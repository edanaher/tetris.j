NB. set random seed
(9!:1)  <. (*/ @: >:) (6!:0) ''

l =: 3 2 $ 2 2 2 0 2 0
o =: 2 2 $ 6 6 6 6
I =: 4 1 $ 4 4 4 4
n =: 3 2 $ 5 0 5 5 0 5
t =: 3 2 $ 1 0 1 1 1 0

incr_nonzeros =: (>: * (>&0))
pieces =: l; (incr_nonzeros |. l); o; I; n; (incr_nonzeros |. n) ; t

width =: 10
height =: 18
outer_width =: width + 6
outer_height =: height + 6

now =: ((6!:1) @ (''"_))
drop_delay =: (1: % (1: + get_score % 5:))

random_piece =: (((? @ #) (> @ {) ]) @ (pieces"_))
rotate_random =: ((|: @ |.) ^: (? @ 4:))
fresh_piece =: (rotate_random @ random_piece)"_

update_board =: (< @ ]) 0 } [
update_piece =: (< @ ]) 1 } [
update_position =: (< @ ]) 2 } [
update_next_piece =: (< @ ]) 3 } [
update_next_drop =: (< @ ]) 4 } [
update_score =: (< @ ]) 5 } [

get_board =: > @ (0:{[)
get_piece =: > @ (1:{[)
get_position =: > @ (2:{[)
get_next_piece =: > @ (3:{[)
get_next_drop =: > @ (4:{[)
get_score =: > @ (5:{[)

add_border =: ((0:,0:,7: , |: , 7:, 0:, (1,#)$0:)^:2)
remove_border =: ((}.@}: ^:3 @ |:)^:2)

shift_piece_one_direction =: (|: @ ((0 #~ }. @ ]) ,"1 [ ,"1 (0 #~ (((-/ @ ]) - (#@|:@[))))))
place_piece_at =: (([ shift_piece_one_direction (outer_width , (}.@]))) shift_piece_one_direction (outer_height , ({.@]))"_)
get_piece_full =: (get_piece place_piece_at (((height"_ + 6: - (# @ get_piece @ [)) , (width"_ + 3:)) (<."1) get_position))

place_piece =: ([ update_board (get_board +. get_piece_full))
remove_piece =: ([ update_board (get_board * ((>./^:2 @ get_piece) - get_piece_full) > 0:))

start_board =. (add_border ((height , width) $ 0))
start_piece =. (fresh_piece 0)
start_next_piece =. (fresh_piece 0)
start_position =. (3 7)
start_next_drop =: ((now 0) + 1.0)
start_state =. place_piece (start_board ; start_piece ; start_position; start_next_piece ; start_next_drop ; 0)

ESC =: (u: 27)
exit =: ((2!:55 @ 0:) @ ((2!:0) @ ('stty echo'"_)) @ (2: (1!:2)~ (,&LF)))
getc_cmdline =: ('stty -echo; (sleep '"_ , ": , '; kill $$) & IFS="" read -n1 c; kill $!; echo ${c/ /+}'"_)
getc_timeout =: (({. @ (2!:0) :: ('.'"_)) @ getc_cmdline)
time_since_start =: (6!:1)

move_location =: ([ update_position ((get_position @ [) + ]))

move_piece_state =: (remove_piece move_location ])
test_collision =: (>&0 @ +./^:2 @ (get_board (*.) get_piece_full))
move_if_no_collision =: ((place_piece @ ])`[ @. (test_collision @ ]))
move_left_right =: ([ move_if_no_collision ([ move_piece_state (0: , ])))
move_left =: ([ move_left_right _1:)
move_right =: ([ move_left_right 1:)

rotate_piece =: (update_piece (|: @ |. @ get_piece)) @ remove_piece
rotate =: ([ move_if_no_collision rotate_piece)

add_new_piece =: ((update_position&start_position) @ (update_next_piece fresh_piece) @ (update_piece get_next_piece))
check_loss =: (]`([: exit 'You lose'"_) @. test_collision)
anchor =: (place_piece @ check_loss @ add_new_piece @ clear_lines)

move_down =: ([ ((place_piece @ ])`(anchor @ [) @. (test_collision @ ])) ([ move_piece_state (1 0)"_))

collide_on_move_down =: (] (test_collision @ move_piece_state)"_ 1 (((i.height) ,"(0) 0))"_) 
drop_distance =: ((+/ @ (*./\) @: -.) @ collide_on_move_down)
drop =: ((move_down ^: drop_distance) @ [)
timed_drop =: (]`(move_down update_next_drop (now + drop_delay)) @. (now  > get_next_drop))

key_actions =: ([`move_left`move_down`rotate`move_right`([: exit 'Goodbye'"_)`drop)
run_key =: (timed_drop @ (key_actions @. ((] * (<&7)) @ ('.hjklq+'"_ i. ]))))

color_cell =: ((": @ (30&+))"0 (ESC"_ , '[' , [ , ';1m', ] , ESC"_ , '[0m'"_)"1 0 ({&' #######'"1))
display_board =: (,/"2 @ (color_cell @ (((}.@}:)^:2 @ |:)^:2) @ get_board))

next_piece_display =: '', '  next piece: ' , '' , ('    ' (,"1) ,/"2 @ color_cell @ get_next_piece)
additional_display =: (('  score: '"_ , (": @ get_score)) , next_piece_display)
pad_additional_display =: (] , ((((height + 2)"_ - #) , (10"_)) $ (' '"_)))
board_output_string =: (display_board (,"1) (pad_additional_display @ additional_display))
print_board =: (2: (1!:2)~ (,/ @ (board_output_string ,"1 (LF"_))))

lines_to_remove =: ((*./"1) @ (>&0))
lines_to_keep =: (-. @ lines_to_remove)
lines_dropped =: ((lines_to_keep"1 # ]) @ (remove_border @ get_board))
add_back_dropped_lines =: ((0&,) ^: (height"_ - #))
clear_lines_board =: add_border @ add_back_dropped_lines @ lines_dropped
do_score =: ([ update_score ((get_score @ [) + (*: @ ])))
clear_lines =: (([ do_score (+/ @ lines_to_remove @ remove_border @ get_board)) update_board clear_lines_board)

run_loop =: ($: @ (] run_key (getc_timeout @ (get_next_drop - now) [ print_board)))

run_loop start_state
