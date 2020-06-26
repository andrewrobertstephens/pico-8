pico-8 cartridge // http://www.pico-8.com
version 27
__lua__
-- main


palt(0,false)
palt(12,true)


left=0
right=1
up=0
down=1
baseline=65
gravity=2
enemy_counter=0
grab_guy=0
knife_guy=1
small_guy=2
player={
	x=384+60,
	y=baseline,
	x2=384+60+16,
	y2=baseline+16,
	walking=false,
	w_index=0,
	direction=left,
	position=up,
	kicking=0,
	punching=0,
	jumping=0,
	speed=1,
	btnup_down=false,
	btn4_down=false,
	btn5_down=false,
	btnleft_down=false,
	btnright_down=false,
	hitbox={
		x=0,
		y=0,
		x2=0,
		y2=0,
	},
	sprite=0,
	grabbed=0,
	hold_time=6,
	health=30,
	strike_hit=0,
}
enemies={}
ticks=0
mode_menu=0
mode_intro=1
mode_start=2
mode_play=3
mode_death=4
mode_gameover=5
mode_complete=6
game_mode=mode_menu
intro_timer=200


function _draw()	
	
	if game_mode==mode_menu then
		cls(0)
		local y=32
		for i=0,112,16 do
			spr(96,i,y)
			spr(96,i,y+20)
			spr(97,i+8,y)
			spr(97,i+8,y+20)
		end
		spr(70,64-7*8/2,y+10,7,1)
		center_print("press 🅾️+❎ to start",64,y+40,7)
		spr(77,5,68,2,2)
		spr(77,106,68,2,2,true)
		
	elseif game_mode==mode_intro then
		cls(12)
		--map(0,0,0,24,64,10)
		draw_level()
		draw_player()
		update_camera()
		local xc=get_camera_x()+64
		center_print("level 1",xc,50,7,true)
	
	elseif game_mode==mode_start then
		cls(12)
		--map(0,0,0,24,64,10)
		draw_level()
		draw_player()
		local xc=get_camera_x()+64
		center_print("level 1",xc,50,7,true)

	elseif game_mode==mode_play then
		cls(12)
		--map(0,0,0,24,64,10)
		draw_level()
		draw_player()	
		draw_enemies()
		
	end
	
	draw_osd()

end


function _update()

	ticks=ticks+1
	
	if game_mode==mode_menu then
		if btn(4) and btn(5) then
			game_mode=mode_intro
		end

	elseif game_mode==mode_intro then
		player.x=64*8-16
		player.y=baseline
		player.direction=left
		camera(64*8-128,player.y-66)
		intro_timer-=1
		if intro_timer<0 then
			game_mode=mode_start
		end
		update_player()

	elseif game_mode==mode_start then
		update_player()
	
	elseif game_mode==mode_play then
		if ticks%50==0 then
			new_enemy()
		end
		update_player()
		update_enemies()
		update_camera()
		
	elseif game_mode==mode_death then
		update_player()
		
	end
	
end


function center_print(text,xc,y,c)
	local w=#text*4
	local x=xc-w/2-4
	rectfill(x-1,y-1,x+w-1,y+5,0)
	print(text,x,y,c)
end


function collision(rect1,rect2)
	return rect1.x<rect2.x2 and
   rect1.x2>rect2.x and
   rect1.y<rect2.y2 and
   rect1.y2>rect2.y
end


function collision_narrow(rect1,rect2)
	return rect1.x+4<rect2.x2-4 and
   rect1.x2-4>rect2.x+4 and
   rect1.y<rect2.y2 and
   rect1.y2>rect2.y
end


function draw_level()
	for i=0,63 do
		local x=i*8*4
		map(0,0,x,24,4,10)
	end
end


function draw_osd()
	local camera_x = get_camera_x()
	local camera_y = get_camera_y()
	--[[
	rectfill(camera_x,camera_y,camera_x+128,camera_y+24,0)
	print("1-000000",camera_x,camera_y,7)
	print("player:_____",camera_x,camera_y+8,7)
	print("enemy: _____",camera_x,camera_y+16,7)
	]]
	print(tostr(player.grabbed),camera_x,camera_y,7)
end

function get_camera_x()
	return peek2(0x5f28)
end

function get_camera_y()
	return peek2(0x5f2a)
end

function start_level()
	game_mode=mode_start
	player.x=64*128-8
	player.y=baseline
end


function strike_collision(hitbox,enemy)
	return hitbox.x<enemy.x2-2 and
   hitbox.x2>enemy.x+2 and
   hitbox.y<enemy.y2-2 and
   hitbox.y2>enemy.y+2	
end


function update_camera()
	if game_mode=="level_start" then
		camera(64*8-128,baseline-66)
	
	else
		camera(player.x-60,baseline-66)
		local camera_x = peek2(0x5f28)
		if camera_x<0 then
			camera(0,baseline-66)
		elseif camera_x>384 then
			camera(384,baseline-66)
		end
	end
	
end


-->8
-- player


-- draw player
function draw_player()
	spr(player.sprite,player.x,player.y,2,2,player.flip_x)	
	if player.strike_hit>0 then
		spr(68,player.hitbox.x-2,player.hitbox.y-2)
	end
	--rectfill(player.hitbox.x,player.hitbox.y,player.hitbox.x2,player.hitbox.y2,10)
end


-- update player
function update_player()

	if ticks%4==0 then
		player.w_index+=1
		if player.w_index>3 then
			player.w_index=0
		end
	end
	
	if player.health<=0 then
		--game_mode=mode_death
	end
	
	if game_mode==mode_intro then
	
	elseif game_mode==mode_start then
		player.walking=true
		if player.x>64*8-64 then
			player.x-=1
		else
			game_mode=mode_play
		end
		
	elseif game_mode==mode_death then
		if player.direction==left then
			player.x+=gravity/2
		else
			player.x-=gravity/2
		end
		player.y+=gravity
		if player.y>get_camera_y()+128 then
			start_level()
		end
		
	else
	
		player.last_direction=player.direction

		if btn(⬅️) and player.jumping==0 then
			player.direction=left
		elseif btn(➡️) and player.jumping==0 then
			player.direction=right
		end

		if player.last_direction!=player.direction then
			player.grabbed-=1
			if player.grabbed<0 then
				player.grabbed=0
			end		
		end
		
		if player.grabbed>1 then
				player.health-=1
		else
			for enemy in all(enemies) do
				if enemy.grabbing==true then
					enemy.dead=true
				end
			end
		end
		
		if btn(⬇️) then
			player.position=down
		elseif player.punching==0 and player.kicking==0 then
			player.position=up
		end
		
		if btn(⬆️) then
			if player.btnup_down==false then
				if player.y==baseline then
					player.jumping=10
				end
			end
			player.btnup_down=true
		else
			player.btnup_down=false
		end
		
		if btn(4) and player.grabbed<1 then
			if player.btn4_down==false then
				player.kicking=10
			end
			player.btn4_down=true
		else
			player.btn4_down=false
		end
		
		if btn(5) and player.grabbed<1 then
			if player.btn5_down==false then
				player.punching=10
			end
			player.btn5_down=true
		else
			player.btn5_down=false
		end
		
		if btn(⬅️) and 
				player.jumping<1 and
				player.kicking<1 and 
				player.punching<1 and 
				player.grabbed<1 and 
				player.position==up then
			player.x-=player.speed
			player.walking=true
		elseif btn(➡️) and 
				player.jumping<1 and
				player.kicking<1 and 
				player.punching<1 and 
				player.grabbed<1 and
				player.position==up then
			player.x+=player.speed
			player.walking=true
		else
			player.walking=false
			player.w_index=0
		end
		
		-- apply gravity
		if player.jumping>5 then
			player.y-=gravity
		else
			player.y+=gravity
			if player.y>baseline then
				player.y=baseline
			end
		end
		
		player.x2=player.x+16
		player.y2=player.y+16
		
		player.kicking-=1
		if player.kicking<0 then
			player.kicking=0
		end
		player.punching-=1
		if player.punching<0 then
			player.punching=0
		end
		player.jumping-=1
		if player.jumping<0 then
			player.jumping=0
		end	
		
		if player.direction==right then
			player.hitbox.x=player.x+12
			player.hitbox.x2=player.hitbox.x+3
		else
			player.hitbox.x=player.x
			player.hitbox.x2=player.hitbox.x+3
		end
		
		if player.position==down then
			player.hitbox.y=player.y+8
			player.hitbox.y2=player.y+12
		else
			player.hitbox.y=player.y
			player.hitbox.y2=player.y+4
		end
		
		if player.strike_hit>0 then
			player.strike_hit-=1
		end
		if player.strike_hit<0 then
			player.strike_hit=0
		end

	end
	
	update_player_sprite()

end


-- update player sprite
function update_player_sprite()
	player.sprite=0

	if game_mode==mode_death then
		player.sprite=46
	else
	
		if player.jumping>0 then
			player.sprite=2
			if player.kicking>player.hold_time then
				player.sprite=38
			elseif player.kicking>0 then
				player.sprite=6
			elseif player.punching>player.hold_time then
				player.sprite=40
			elseif player.punching>0 then
				player.sprite=6
			end
		elseif player.position==up then
			if player.kicking>player.hold_time then
				player.sprite=8
			elseif player.kicking>0 then
				player.sprite=6
			elseif player.punching>player.hold_time then
				player.sprite=12
			elseif player.punching>0 then
				player.sprite=10
			elseif player.walking==true then
				if player.w_index==3 then
					player.sprite=2
				else
					player.sprite=player.w_index*2
				end
			end
		else
			player.sprite=14
			if player.kicking>player.hold_time then
				player.sprite=42
			elseif player.kicking>0 then
				player.sprite=14
			elseif player.punching>player.hold_time then
				player.sprite=34
			elseif player.punching>0 then
				player.sprite=32
			end
		end
	end
	player.flip_x=false
	if player.direction==left then
		player.flip_x=true
	end
end
-->8
-- enemies


function draw_enemies()
	for enemy in all(enemies) do
		local index=100
		if enemy.kind==1 then
			index=128
		elseif enemy.kind==2 then
			index=192
		end
		local sprite=enemy.w_index*2+index
		local flip_x=false
		if enemy.dead==true then
			if enemy.kind==0 then
				sprite=110
			elseif enemy.kind==1 then
				sprtie=140
			elseif enemy.kind==2 then
				sprite=198
			end
		end
		if enemy.direction==left then
			flip_x=true
		end
		spr(sprite,enemy.x,enemy.y,2,2,flip_x)
	end
end


function new_enemy()
	local camera_x = peek2(0x5f28)
	enemy={
		y=baseline,
		w_index=0,
		direction=flr(rnd(2)),
		kind=0,
		health=1,
		speed=1.5,
		grabbing=false,
	}
	if enemy.direction==left then
		enemy.x=player.x+64
	else
		enemy.x=player.x-64
	end
	enemy.x2=enemy.x+16
	enemy.y2=enemy.y+16
	if enemy_counter>5 then
		enemy.kind=2
		enemy.health=2
		enemy_counter=0
	end
	add(enemies,enemy)
	enemy_counter+=1
end


function update_enemies()

	for enemy in all(enemies) do

		if ticks%3==0 then
			enemy.w_index=enemy.w_index+1
			if enemy.w_index>1 then
				enemy.w_index=0
			end
		end
		
		if strike_collision(player.hitbox,enemy) and (player.punching>5 or player.kicking>5) then
			player.strike_hit=3
			enemy.health-=1
			if enemy.health<1 then
				enemy.dead=true
			end
		end
		
		if enemy.dead==true then
			if enemy.direction==right then
				enemy.x-=gravity/2
				enemy.y+=gravity
			else
				enemy.x+=gravity/2
				enemy.y+=gravity
			end

		else

			if enemy.kind==grab_guy then
				update_grab_guy(enemy)
				
			elseif enemy.kind==1 then
				update_knife_guy(enemy)			
				
			elseif enemy.kind==2 then
				update_small_guy(enemy)	
					
			end

		end
		
		enemy.x2=enemy.x+16
		enemy.y2=enemy.y+16
		
		if enemy.y>get_camera_y()+128 then
			del(enemies,enemy)
		end

	end

end


function update_grab_guy(enemy)
	if enemy.grabbing==false and collision_narrow(enemy,player) then
		player.grabbed=10
		enemy.grabbing=true
	end
	if enemy.grabbing==false then
		if enemy.direction==right then
			enemy.x+=enemy.speed
		else
			enemy.x-=enemy.speed
		end				
	end
end


function update_knife_guy(enemy)
	if enemy.knife==false then
		if enemy.direction==right then
			enemy.x+=enemy.speed
		else
		end
	end
end

function update_small_guy(enemy)
		if enemy.direction==right then
			enemy.x+=enemy.speed
		else
			enemy.x-=enemy.speed
		end				
end
__gfx__
ccccccc0000cccccccccccc0000cccccccccccc0000ccccccccccccccccccccccccccc0000cccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccc0999cccccccccccc0999cccccccccccc0999cccccccccccc0000ccccccccccc0999cccccccccccccc0000cccccccccccccc0000ccccccccccccccccccc
cccccc0919cccccccccccc0919cccccccccccc0919ccccccccccc0999cccccccccccc0919ccccccccccccc0999cccccccccccccc0999cccccccccccccccccccc
cccccc9999cccccccccccc9999cccccccccccc9999ccccccccccc0919ccccccccccccc999ccccccccccccc0919cccccccccccccc0919cccccccccccccccccccc
cccccc799ccccccccccccc799cccccccccccccc99cccccccccccc0999cc9ccccccccc799ccccc700ccccccc999cc9cccccccccccc999ccccccccccc0000ccccc
ccccc00770ccccccccccc70077ccccccccccccc700ccccccccccc7777cc9cccccccc770970cc7790cccccc00779c9ccccccccccc07700999cccccc0999cccccc
cccc000077ccccccccccc00077cccccccccccc7000cccccccccc00797099ccccccc0007007077790ccccc70009909cccccccccc0770009c9cccccc0919cccccc
cccc9007770cccccccccc0097ccccccccccccc7009cccccccccc0099809cccccccc0007798877cccccccc70999099cccccccccc07700ccccccccccc999cccccc
cccc99777c99ccccccccc09988cccccccccccc70999ccccccccc099887cccccccccc09999878cccccccccc7799cccccccccccccc7777ccccccccc00790cccccc
ccccc9988cc99ccccccccc99878ccccccccccc888999ccccccccc987787cccccccccc999877cccccccccccc8888cccccccccccc8888ccccccccc0077770ccccc
ccccc79978ccccccccccccc997cccccccccccc7777cccccccccccc777777ccccccccccc777ccccccccccccc77878ccccccccccc77777cccccccc0077770ccccc
cccccc67777cccccccccccc777cccccccccccc77777ccccccccccc777c77ccccccccccc777cccccccccccc777c777ccccccccc777c777ccccccc9958899ccccc
ccccc776677ccccccccccc7777ccccccccccc777c77cccccccccc7777c99cccccccccccc77ccccccccccc777ccc77cccccccc777ccc77cccccccc998798ccccc
cccc777cc777ccccccccc0977ccccccccccc777cc777cccccccc0977cc000ccccccccccc777ccccccccc777ccc777ccccccc777ccc777ccccccc77977777cccc
ccc099cccc99ccccccccc09cccccccccccc099cccc99cccccccc09ccccccccccccccccccc99ccccccccc99cccc99cccccccc99cccc99cccccccc997cc799cccc
ccc0000ccc000cccccccc0ccccccccccccc0000ccc000ccccccc0ccccccccccccccccccc000ccccccccc000ccc000ccccccc000ccc000cccccc000cccc000ccc
ccccccccccccccccccccccccccccccccccccccccccccccccccccccc0000cccccccccccccc0000cccccccccccccccccccccccccc0000ccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccc00ccccccccccccc0999cccccccccccccc0999cccccccccccccccccccccccccc0999cccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccc0095cccccccccccc0919cccccccccccccc0919cccccccccccccccccccccccccc0919ccccccccc0cccccccccccc
ccccccccccccccccccccccccc0000ccccccccc0999cccccccccccc9999ccccccccccccccc999cccccccccccccccccccccccccc9999cccccccc099ccccc99cccc
ccccccc0000ccccccccccccc0999cccccccccc799ccccccccccccc799cccccc0cccccccc07700999ccccccc0000ccccccccccc799ccccccccc0999cccc99cccc
cccccc0999cccccccccccccc0919ccccccccc00770ccccccccccc70777cccc90ccccccc0770009c9cccccc0999ccccccccccc70777cccccccc0099c0099ccccc
cccccc0919ccccccccccccccc999cccccccc0007709cccccccccc007970cc790ccccccc07700cccccccccc0919ccccccccccc00797ccccccccc0777709cccccc
ccccccc999cc9ccccccccccc07700999cccc90077799ccccccccc0099887777ccccccccc7777ccccccccccc999ccccccccccc009988cccccccc000777ccccccc
cccccc00779c9cccccccccc0770009c9ccc990888cc99cccccccc099887877ccccccccc8888cccccccccc00790ccccccccccc0998877ccccccc00077877ccccc
ccccc70009909cccccccccc07700ccccccc9cc7878c99ccccccccc9877779cccccccccc77777cccccccc0077770ccccccccccc9877877cccccc007787777cccc
ccccc70999099ccccccccccc7777ccccccc99c777cccccccccccccc7777cc9cccccccc777777cccccccc0077770cccccccccccc777777cccccc990877767cccc
cccccc889987ccccccccccc8888cccccccccccc777cccccccccccccc777ccccccccccc777099cccccccc9958899cccccccccccc777099ccccccc99977077cccc
cccccc7777787ccccccccc7777787cccccccccc777cccccccccccc7777ccccccccccc7777c000cccccccc9987987cccccccccc7777c000ccccccc99770977ccc
cccc97777c777ccccccc97777c777ccccccccc097cccccccccccc097cccccccccccc0977cccccccccccc7797777777ccccccc0977cccccccccccccccc09777cc
ccc09777ccc99cccccc09777ccc99cccccccccc09cccccccccccc09ccccccccccccc09cccccccccccccc997cccc77990ccccc09cccccccccccccccccc0c7099c
ccc00cccccc000ccccc00cccccc000cccccccccc00ccccccccccc0cccccccccccccc0cccccccccccccc000ccccccc000ccccc0cccccccccccccccccccccc0000
ccccccccbbbbbb3688888888888a8888cacccccccccccccc00990099009900990099999000099999000000000999999009900990cccccaa3333c38cc00000000
ccccccccbbbbb36baaaaa8aaaa8a8aaacc7ccccacccc33cc08990899089908990899999900999999000000008999999089908990ccccc833883833cc00000000
ccccccccbbbb36bbccccc8a88a8a8a88cccccc7cccc3333c08999999089908990899889908998880000000008998880089908990cccc8c833333c7cc00000000
ccccccccbbb36bbbccccc8a8888a8888ccccccccccc37ccc08999990089908990899089908990000000000008999999089908990ccccc8c83ac7cccc00000000
ccccccccbb36bbbbccccc8aaaa8a8aaacccccccccccc37cc08999990089908990899089908990099000000008999999089908990ccccccc83aaccccc00000000
ccccccccb36bbbbbccccc888888a8888c7cccccccc88c37c08998899089999990899089908999999000000008998880089999990cccccc8c83baaccc00000000
cccccccc33333333cccccccccc8a8cccacccc7ccc833837c08990899089999900899089908999999000000008990000089999900ccccccccc333bacc00000000
cccccccc00000000cccccccccc8a8cccccccccac83c337cc08800880088888000880088008888880000000008880000088888000ccccccccc8383bac00000000
ffffffff7ccccccccccccccccc8a8ccccccaacccccccccccccccccccccffffccccffeecccccc7cccccccc8ccccc77ccccccccccccccccccccc383bac00000000
4444444467cccccccccccccccc8a8ccccca33acccccc33cccccccccccbffff8ccfeeffecc77cc77ccc888aaccc7667cccccccccccccccc8cc833bbac00000000
ffffffffc67cccccaaaaaaaaaaaaaaaaccbaabccccc3333cccccc8ccfbbff88feeffeeffc7fcff7cc8aaa777cc7777cccccccccccccc8c8ccc3bbacc00000000
ffffffffc444ffff8888888888888888ca3bb3acccc377ccbcc8cccbffbb88ffeeffeeff7ccccfcc8a77778cccc76cccccccccccccccc8a8c3bbaccc00000000
44444444ccc555ccaaaaaaaaaaaaaaaacba33abccccc337cc8cccc8cfff88fffffeeffeeccfcccc7c8aaa777cc6777ccccc77cccccc88aa338bacccc00000000
ffffffffcccc67ccccccccccccccccccc3baab3ccccccc37cb3cc3bcff88bbffffeeffeec7ffcf7ccc888aaccc7667ccccc76cccccccc8333baccccc00000000
ffffffffccccc67ccccccccccccccccccc3bb3ccc8888c373c8338c3c88ffbbcceffeefcc77cc77cccccc8cccc7777cccc6777cccccccccc3acccccc00000000
ffffffffcccccc67ccccccccccccccccccc33ccc83c3337cc3b88b3cccffffcccceeffccccc7ccccccccccccccc76cccccc66ccccccccccccccccccc00000000
4444444444444444cccccccc88888888ccccccc2222cccccccccccc2222cccccccccc992222cccccccccc992222cccccccccccc2222ccccccccccccccccccccc
8888888888888888cccccccca8aaaaaacccccc2999cccccccccccc2999ccccccccccc99999ccccccccccc99999cccccccccccc2999cccccccccccccccccccccc
8aaaaaa88aaaaaa8cc1ccccca8cccccccccccc2929cccccccccccc2929cccccccccccff929cccccccccccff929cccccccccccc2929ccccccccc4cccccccccccc
8a8888a88a8888a844177777a8cccccccccccc9999cccccccccccc9999cccccccccccff999cccccccccccff999cccccccccccc9999cccccccc499ccccc99cccc
8a8aaaa88aaaa8a84417777ca8cccccccccccc299ccccccccccccc299ccccccccccccfff9ccccccccccccfff9ccccccccccccc299ccccccccc4999cccc99cccc
8a888888888888a8cc1ccccc88ccccccccccc2f222cccccccccccff22fccccccccccccff22ccccccccccccff22ccccccccccccff22cccccccc4499cffffccccc
8aaaaaaaaaaaaaa8cccccccccccccccccccccfff22ccccccccccfff222fcccccccccccff22ccccccccccccff22ccccccccccccff22ccccccccc42222ffcccccc
8888888888888888cccccccccccccccccccccfff2299ccccccccff2222fccccccccccc2222cccccccccccc2222ccccccccccccfff299cccccccff2222ccccccc
111111111122221188888888ccccccccccccccf99299ccccccccff2222f99cccccccccc222cccccccccccc2222cccccccccccccfff9ccccccccff2222ffccccc
11111111118e8811aaaaaaaaccccccccccccccf99fccccccccccf9922cc99ccccccccccfffcccccccccccc222cccccccccccccc2ff99cccccccff222ffffcccc
1c1c1c1c118e8811ccccccccaaaaaaaacccccccfffccccccccccc99fffcccccccccccccfffccccccccccccffffcccccccccccccfffcccccccccffc2fff2fcccc
c1c1c1c1c18e8811cccccccc88888888cccccccfffccccccccccccfffffccccccccccccfffccccccccccccfffffccccccccccccfffccccccccccf99ff2ffcccc
1ccc1ccc17888871ccccccccaaaaaaaaccccccffffcccccccccccffffffcccccccccccffffcccccccccccffffffcccccccccccffffccccccccccc99ff29ffccc
cc1ccc1c11777711ccccccccccccc67cccccc29ffcccccccccccfffccfffccccccccc29ffcccccccccccfffccfffccccccccccfffcccccccccccccccc29fffcc
ccccccccc111111ccccccccccccccc67ccccc29cccccccccccc299cccc99ccccccccc29cccccccccccc299cccc99cccccccccc299cccccccccccccccc2cf299c
ccccccccccccccccccccccccccccccc6ccccc222ccccccccccc2222ccc222cccccccc222ccccccccccc2222ccc222ccccccccc2222cccccccccccccccccc2222
ccccccc1111cccccccccccc1111ccccc777199c1111cccccccccccc1111cccccccccccc1111ccccccccccccccccccccccccccccccccccccc0000000000000000
cccccc7777cccccccccccc7777cccccccc71997777cccccccccc7c7777cccccccccccc7777cccccccccccccc1111cccccccccccccccccccc0000000000000000
ccccc71919ccccccccccc71919ccccccccc1c71919ccccccccccc71919ccccccccccc71919ccccccccccc7c7777cccccccc1cccccccccccc0000000000000000
cccccc9999cccccccccc7c9999ccccccccccc79999cccccccccccc9999ccccccccccc79999cccccccccccc71919ccccccc177ccccc99cccc0000000000000000
cccccc199ccccccccccccc199cccccccccccc7199ccccccccccccc199cccccccccccc7199cccccccccccccc9999ccccccc7999cccc99cccc0000000000000000
ccccc77117ccccccccccc17111ccccccccccc11111ccccccccccc7711777799cccccc11111ccccccccccccc199cccccccc7199c7777ccccc0000000000000000
cccc7771117cccccccccc77711ccccccccccc17711cccccccccc7771117779ccccccc17711ccccccccccc77111ccccccc7c1111177cccccc0000000000000000
cccc7711117cccccccccc7771199ccccccccc1777799cccccccc7711117ccccccccc71777799cccccccc7771117cccccccc771111ccccccc0000000000000000
cccc771111799ccccccccc799199cccccccccc177799cccccccc771111cccccc777191177799cccccccc77111177ccccccc77111177ccccc0000000000000000
cccc79911cc99ccccccccc7997cccccccccccc1111cccccccccc79911ccccccccc71991111cccccccccc79911cc799ccccc771117777cccc0000000000000000
ccccc99777ccccccccccccc777ccccccccccccc777ccccccccccc997777cccccccc1ccc777ccccccccccc997777c99ccccc77c777717cccc0000000000000000
cccccc77777cccccccccccc777ccccccccccccc777cccccccccccc777777ccccccccccc777cccccccccccc777777cccccccc79977177cccc0000000000000000
ccccc777777ccccccccccc7777cccccccccccc7777ccccccccccc777c777cccccccccc7777ccccccccccc777c777ccccccccc99771977ccc0000000000000000
cccc777cc777ccccccccc1977cccccccccccc1977ccccccccccc777ccc77ccccccccc1977ccccccccccc777ccc77ccccccccccccc19777cc0000000000000000
ccc199cccc99ccccccccc19cccccccccccccc19cccccccccccc199ccc199ccccccccc19cccccccccccc199ccc199ccccccccccccc1c7199c0000000000000000
ccc1111ccc111cccccccc111ccccccccccccc111ccccccccccc1111ccc111cccccccc111ccccccccccc1111ccc111ccccccccccccccc11110000000000000000
cccccccc4444cccccccccccc4444cccc4444499c4444cccccccccccc4444cccccccc4ccccccccccccccccccccccccccccccccccccccccccc0000000000000000
ccccccc4999cccccccccccc4999cccccccccc994999cccccccccccc4999cccccccccc4cccccccccccccccccccccccccccccccccccccccccc0000000000000000
ccccccc4919cccccccccccc4919ccccccccccc64919cccccccccccc4919ccccccccccc4cccccccccccccccccccccccccccc4cccccccccccc0000000000000000
ccccccc9999cccccccccccc9999ccccccccccc69999cccccccccccc9999cccccccccccc4c4444cccccccccccc4444ccccc499ccccc99cccc0000000000000000
ccccccc499ccccccccccccc499cccccccccccc6499ccccccccccccc499ccccccccccccc94999cccccccccccc4999cccccc4999cccc99cccc0000000000000000
cccccc66446ccccccccccc46444ccccccccccc44444ccccccccccc6644666699ccccccc949196ccccccccccc4919cccccc4499c6666ccccc0000000000000000
ccccc6664446cccccccccc66644ccccccccccc46644cccccccccc6664446669ccccccccc99996ccccccccccc9999ccccccc4444466cccccc0000000000000000
ccccc6644446cccccccccc6664499ccccccccc4666699cccccccc6644446cccccccccccc49966ccccccccccc499cccccccc664444ccccccc0000000000000000
ccccc664444699ccccccccc699499cccccccccc466699cccccccc664444ccccccccccc664446cccccccccc6644466699ccc66444466ccccc0000000000000000
ccccc69944cc99ccccccccc6996cccccccccccc4444cccccccccc69944ccccccccccc666444cccccccccc6664446669cccc664446666cccc0000000000000000
cccccc99666ccccccccccccc666ccccccccccccc666ccccccccccc996666ccccccccc6644466ccccccccc6644466ccccccc66c666646cccc0000000000000000
ccccccc66666cccccccccccc666ccccccccccccc666cccccccccccc666666cccccccc69946666cccccccc69946666ccccccc69966466cccc0000000000000000
cccccc666666ccccccccccc6666cccccccccccc6666ccccccccccc666c666ccccccccc9966666ccccccccc9966666cccccccc99664966ccc0000000000000000
ccccc666cc666ccccccccc4966cccccccccccc4966ccccccccccc666ccc66cccccccc6666cc66cccccccc6666cc66cccccccccccc49666cc0000000000000000
cccc499cccc99ccccccccc49cccccccccccccc49cccccccccccc499ccc499ccccccc499ccc499ccccccc499ccc499cccccccccccc4c6499c0000000000000000
cccc4444ccc444cccccccc444ccccccccccccc444ccccccccccc4444ccc444cccccc4444ccc444cccccc4444ccc444cccccccccccccc44440000000000000000
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc88ccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc98cccccccccccccccccccccccc
ccccccc4444cccccccccccc4444cccccccccccc4444cccccccccc4cccc99cccccccccccc44ccccccccccccccccccccccccccc33933cccccccccccccccccccccc
cccccc4999cccccccccccc4999cccccccccccc4999cccccccccc499ccc99ccccccccccc4994cccccccccc388ccccccccccccc333333cccccccccc4c33c33c8cc
cccccc4919cccccccccccc4919cccccccccccc4919cccccccccc4999c33cccccccccccc499cccccccccc33888ccccccccccccc38888ccccccccc4993333398cc
cccccc9999cccccccccccc9999cccccccccccc9999cccccccccc449883cccccccccccc88333ccccccccc3388844cccccccccc333888ccccccccc499338398ccc
cccccc3883cccccccccccc338ccccccccccccc833ccccccccc99c8888c33ccccccccc888333cccccccc893833994ccccccccc33388ccccccccccc4488833cccc
ccccc338883ccccccccccc338ccccccccccccc833ccccccccc99338883333cccccccc88883cccccccc8933333994cccccccccc994cccccccccccccc88833cccc
ccccc3388899cccccccccc3399cccccccccccc833399ccccccc3333833399cccccccc333333ccccccc8c33c33c4cccccccccc4994ccccccccccccccc883ccccc
cccccc998899ccccccccccc399ccccccccccccc33399ccccccccccc333c888cccccccc33933ccccccccccccccccccccccccccc44cccccccccccccccccccccccc
cccccc9933ccccccccccccc33cccccccccccccc33ccccccccccccccc333ccccccccccccc89cccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccc33cc33cccccccccccc33cccccccccccccc33ccccccccccccccc833cccccccccccccc88ccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccc39cc39ccccccccccc39cccccccccccccc39cccccccccccccccc893ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccc888c888cccccccccc888ccccccccccccc888ccccccccccccccc8ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
__gff__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001010101010000000000000000000000010101010000000000000000000000000101010100000000000000000000000001010101000000000000000000000000
0000000000000000000000000000020000000000000000000000000000000200020202020202020202020202020202000202020202020202020202020002020000000000000002020202020202020202000000000000000202020202020202020000020202020202020202020202020000000202020202020202020202020200
__map__
4141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141
4243637242436372424363724243637242436372424363724243637242436372424363724243637242436372424363724243637242436372424363724243637242436372424363724243637242436372424363724243637242436372424363724243637242436372424363724243637242436372424363724243637242436372
5253525252535252525352525253525252535252525352525253525252535252525352525253525252535252525352525253525252535252525352525253525252535252525352525253525252535252525352525253525252535252525352525253525252535252525352525253525252535252525352525253525252535252
4040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040
4040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040
4040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040
4040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040
5050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050
6160616061606160616061606160616061606161606160616061606160616160616061606160616061606160616061606160616061606160616061606160616061606160616061606161606160616061606160616160616061606160616061606160616061606160616160616061606160616061606160616061606160616061
4141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141
4141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141
4243637242436372424363724243637242436372424363724243637242436372424363724243637242436372424363724243637242436372424363724243637242436372424363724243637242436372424363724243637242436372424363724243637242436372424363724243637242436372424363724243637242436372
5253525252535252525352525253525252535252525352525253525252535252525352525253525252535252525352525253525252535252525352525253525252535252525352525253525252535252525352525253525252535252525352525253525252535252525352525253525252535252525352525253525252535252
4040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040
4040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040
4040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040
4040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040
5050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050
6061606160616061606160616061606160616061606160616061606160616061606160616061606160616061606160616061606160616061606160616061606160616061606160616061606160616061606160616061606160616061606160616061606160616061606160616061606160616061606160616061606160616061
4141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141
4141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141
4243637242436372424363724243637242436372424363724243637242436372424363724243637242436372424363724243637242436372424363724243637242436372424363724243637242436372424363724243637242436372424363724243637242436372424363724243637242436372424363724243637242436372
5253525252535252525352525253525252535252525352525253525252535252525352525253525252535252525352525253525252535252525352525253525252535252525352525253525252535252525352525253525252535252525352525253525252535252525352525253525252535252525352525253525252535252
4040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040
4040514040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040
4040405140404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040
4040404051404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040
5050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050
6061606160616061606160616061606160616061606160616061606160616061606160616061606160616061606160616061606160616061606160616061606160616061606160616061606160616061606160616061606160616061606160616061606160616061606160616061606160616060616061606160616061606160
7170707071707070717070707170707071707070717070707170707071707070717070707170707071707070717070707170707071707070717070707170707071707070717070707170707071707070717070707170707071707070717070707170707071707070717070707170707071707071707070717070707170707071
__sfx__
000101161a7501a750177501675013750127501175010750107100f7200e7500e7300e7100e7500e7200f7501075010750117501275013750147501575017750187501a7501c7501d7501f750227502475027750
