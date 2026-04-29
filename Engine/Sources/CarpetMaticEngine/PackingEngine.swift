import Foundation

public enum PackingEngine {

    public static func pack(_ project: Project) throws -> PackingResult {
        guard Project.allowedRollWidthsMetres.contains(project.rollWidthMetres) else {
            throw PackingError.invalidRollWidthMetres(project.rollWidthMetres)
        }

        let rollWidthCM = project.rollWidthCM
        var queue: [PieceWithContext] = []
        for room in project.rooms {
            for piece in room.pieces {
                guard piece.widthCM > 0, piece.lengthCM > 0 else {
                    throw PackingError.nonPositiveDimension(pieceID: piece.id)
                }
                if piece.effectiveWidthCM > rollWidthCM {
                    throw PackingError.pieceWiderThanRoll(
                        pieceID: piece.id,
                        pieceWidthCM: piece.effectiveWidthCM,
                        rollWidthCM: rollWidthCM
                    )
                }
                queue.append(PieceWithContext(piece: piece, roomID: room.id))
            }
        }

        guard !queue.isEmpty else {
            return PackingResult(totalLengthCM: 0, perRoom: [], placements: [])
        }

        // First-Fit-Decreasing shelf packer:
        //   1. Sort pieces by effective length descending.
        //   2. Open a shelf whose height = the longest unplaced piece's length.
        //   3. Place pieces left-to-right that fit the shelf height and remaining width.
        //   4. When nothing more fits, advance to the next shelf above.
        queue.sort { $0.piece.effectiveLengthCM > $1.piece.effectiveLengthCM }

        var placements: [PiecePlacement] = []
        var rollLengthUsedCM = 0

        while !queue.isEmpty {
            let shelfHeightCM = queue[0].piece.effectiveLengthCM
            var widthUsedCM = 0
            var idx = 0

            while idx < queue.count {
                let candidate = queue[idx]
                let pieceWidth = candidate.piece.effectiveWidthCM
                let pieceLength = candidate.piece.effectiveLengthCM

                let fitsInShelfHeight = pieceLength <= shelfHeightCM
                let fitsInRemainingWidth = widthUsedCM + pieceWidth <= rollWidthCM

                if fitsInShelfHeight && fitsInRemainingWidth {
                    placements.append(PiecePlacement(
                        pieceID: candidate.piece.id,
                        roomID: candidate.roomID,
                        widthCM: pieceWidth,
                        lengthCM: pieceLength,
                        pileDirection: candidate.piece.effectivePileDirection,
                        xCM: widthUsedCM,
                        yCM: rollLengthUsedCM
                    ))
                    widthUsedCM += pieceWidth
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

    private struct PieceWithContext {
        let piece: Piece
        let roomID: UUID
    }

    private static func buildRoomBreakdowns(
        project: Project,
        placements: [PiecePlacement]
    ) -> [RoomBreakdown] {
        var byRoom: [UUID: [PiecePlacement]] = [:]
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
                pieces: roomPlacements
            )
        }
    }
}
