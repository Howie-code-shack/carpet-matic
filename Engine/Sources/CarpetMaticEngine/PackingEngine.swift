import Foundation

public enum PackingEngine {

    public static func pack(_ project: Project) throws -> PackingResult {
        guard Project.allowedRollWidthsMetres.contains(project.rollWidthMetres) else {
            throw PackingError.invalidRollWidthMetres(project.rollWidthMetres)
        }

        let rollWidthCM = project.rollWidthCM

        // Step 1: validate rooms.
        for room in project.rooms {
            guard room.widthCM > 0, room.lengthCM > 0 else {
                throw PackingError.invalidRoomDimensions(roomID: room.id)
            }
        }

        // Step 2: generate strips for every room.
        var queue: [StripWithContext] = []
        for room in project.rooms {
            let strips = strips(for: room, rollWidthCM: rollWidthCM)
            for strip in strips {
                queue.append(StripWithContext(strip: strip, roomID: room.id))
            }
        }

        guard !queue.isEmpty else {
            return PackingResult(totalLengthCM: 0, perRoom: [], placements: [])
        }

        // Step 3: First-Fit-Decreasing shelf packer.
        //   Sort by length descending, open shelves whose height = the longest
        //   unplaced strip, fill left-to-right with anything that fits.
        queue.sort { $0.strip.lengthCM > $1.strip.lengthCM }

        var placements: [StripPlacement] = []
        var rollLengthUsedCM = 0

        while !queue.isEmpty {
            let shelfHeightCM = queue[0].strip.lengthCM
            var widthUsedCM = 0
            var idx = 0

            while idx < queue.count {
                let candidate = queue[idx]
                let stripWidth = candidate.strip.widthCM
                let stripLength = candidate.strip.lengthCM

                let fitsHeight = stripLength <= shelfHeightCM
                let fitsWidth = widthUsedCM + stripWidth <= rollWidthCM

                if fitsHeight && fitsWidth {
                    placements.append(StripPlacement(
                        id: candidate.strip.id,
                        roomID: candidate.roomID,
                        widthCM: stripWidth,
                        lengthCM: stripLength,
                        pileDirection: candidate.strip.pileDirection,
                        xCM: widthUsedCM,
                        yCM: rollLengthUsedCM
                    ))
                    widthUsedCM += stripWidth
                    queue.remove(at: idx)
                } else {
                    idx += 1
                }
            }

            rollLengthUsedCM += shelfHeightCM
        }

        let perRoom = buildRoomBreakdowns(project: project, placements: placements)
        return PackingResult(
            totalLengthCM: rollLengthUsedCM,
            perRoom: perRoom,
            placements: placements
        )
    }

    /// Generate the strips needed to carpet a room on a given roll.
    /// Strip axis is determined by the room's pile direction:
    ///  * up/down → strips run along Length (each strip is some-width × Length).
    ///  * left/right → strips run along Width (each strip is some-width × Width).
    /// First n−1 strips are roll-width wide; the last is the remainder.
    /// Internal so tests can target it directly.
    static func strips(for room: Room, rollWidthCM: Int) -> [Piece] {
        let stripsAlongLength = room.pileDirection.stripsAlongLength
        let perpDimensionCM = stripsAlongLength ? room.widthCM : room.lengthCM
        let stripLengthCM   = stripsAlongLength ? room.lengthCM : room.widthCM

        var strips: [Piece] = []
        var remaining = perpDimensionCM
        while remaining > 0 {
            let stripWidth = min(remaining, rollWidthCM)
            strips.append(Piece(
                widthCM: stripWidth,
                lengthCM: stripLengthCM,
                pileDirection: room.pileDirection
            ))
            remaining -= stripWidth
        }
        return strips
    }

    private struct StripWithContext {
        let strip: Piece
        let roomID: UUID
    }

    private static func buildRoomBreakdowns(
        project: Project,
        placements: [StripPlacement]
    ) -> [RoomBreakdown] {
        var byRoom: [UUID: [StripPlacement]] = [:]
        for placement in placements {
            byRoom[placement.roomID, default: []].append(placement)
        }
        return project.rooms.compactMap { room in
            guard let roomPlacements = byRoom[room.id], !roomPlacements.isEmpty else {
                return nil
            }
            return RoomBreakdown(
                roomID: room.id,
                roomName: room.name,
                kind: room.kind,
                strips: roomPlacements
            )
        }
    }
}
