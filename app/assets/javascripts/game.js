var moves = [];
var id, player, movingPlayer, move = 0;

function getCell(position) {
    return $('.cell[position=' + position + ']');
}

function showPromote() {
    $('#promote').css('visibility', 'visible');
    $('#promote .cell').eq(0).addClass('selected');
}

function hidePromote() {
    $('#promote').css('visibility', 'hidden');
}

function update() {
    $.getJSON('/board/' + id,
        function (data) {
            move = data.move;
            moves = data.moves;
            movingPlayer = data.player;

            var cell, piece;
            for (var i = 0; i < 64; i++) {
                cell = getCell(i);
                piece = data.pieces[i];
                if (piece) {
                    cell.attr('piece-color', piece.color ? 'white' : 'black');
                    cell.attr('piece-type', piece.type);
                } else {
                    cell.attr('piece-color', 'none');
                    cell.attr('piece-type', 'none');
                }
            }

            $('#moving-player').text((movingPlayer ? 'White' : 'Black') + "'s turn");
            $('#check-state').text(data.checkState == 'check' ? 'Check!' : data.checkState == 'checkmate' ?
                'Checkmate!' : data.checkState == 'stalemate' ? 'Stalemate!' : '');
            $('#win-state').text(data.winState == 'white' ? 'White win!' : data.winState == 'black' ?
                'Black win!' : data.winState == 'draw' ? 'Draw!' : '');
        });
}

function clearSelection() {
    $('.cell.selected').removeClass('selected');
    $('.cell.move').removeClass('move');
    hidePromote();
}

$(function () {
    id = $('input[name=id]').val();
    player = $('input[name=player]').val() == 'true' ? true : false;

    setInterval(function () {
        $.getJSON('/move/' + id,
            function (data) {
                if (move != data) {
                    update();
                }
            });
    }, 1000);

    $('.cell').click(function () {
        if (movingPlayer != player) {
            return;
        }

        var fromCell, toCell, canPromote = false;
        if ($(this).attr('position')) {
            var selected = $('.cell.selected');
            if ($(this).attr('piece-color') == (movingPlayer ? 'white' : 'black')) {
                clearSelection();
                $(this).addClass('selected');
                var position = $(this).attr('position');
                for (var i = 0; i < moves.length; i++) {
                    if (moves[i][0] == position) {
                        fromCell = getCell(moves[i][0]);
                        toCell = getCell(moves[i][1]);
                        toCell.addClass('move');

                        if (fromCell.attr('piece-type') == 'pawn' &&
                            (moves[i][1] >= 56 && moves[i][1] < 64 ||
                                moves[i][1] >= 0 && moves[i][1] < 8)) {
                            canPromote = true;
                        }
                    }
                }

                if (canPromote) {
                    showPromote();
                } else {
                    hidePromote();
                }
            } else if ($(this).hasClass('move')) {
                $.post('/move/' + id, {
                        from: selected.attr('position'),
                        to: $(this).attr('position'),
                        player: player,
                        piece: $('#promote .selected').attr('piece-type')
                    },
                    function () {
                        clearSelection();
                        update();
                    }
                )
                ;
            } else {
                clearSelection();
            }
        }
        else {
            $('#promote .selected').removeClass('selected');
            $(this).addClass('selected');
        }
    });

    update();
})