pico-8 cartridge // http://www.pico-8.com
version 27
__lua__
-- main

palt(0,false)
palt(12,true)


left=-1
right=1
up=-1
down=1
baseline=65
gravity=2
ticks=0

logfile="kungfu"


function _init()
	init_modes()
	init_levels()
	init_player()
	init_enemies()
	init_projectiles()
	change_mode(mode_menu)
	printh("kungfu.p8 log",logfile,true)
end


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
		spr(78,5,68,2,2)
		spr(78,106,68,2,2,true)
		
	elseif game_mode==mode_intro then
		cls(12)
		draw_level()
		draw_player()
		local xc=get_camera_x()+64
		center_print("level 1",xc,50,7,true)
		draw_osd()
	
	elseif game_mode==mode_start then
		cls(12)
		draw_level()
		draw_player()
		local xc=get_camera_x()+64
		center_print("level 1",xc,50,7,true)
		draw_osd()

	elseif game_mode==mode_play then
		cls(12)
		draw_level()
		draw_projectiles()
		draw_player()	
		draw_enemies()
		draw_osd()
		
	elseif game_mode==mode_death then
		cls(12)
		draw_level()
		draw_projectiles()
		draw_player()
		draw_enemies()
		draw_osd()
		
	end
	
end


function _update()

	ticks=ticks+1
	
	if game_mode==mode_menu then
		if btn(4) and btn(5) then
			change_mode(mode_intro)
		end

	elseif game_mode==mode_intro then
		camera(64*8-128,player.y-66)
		intro_timer-=1
		update_player()
		if intro_timer<0 then
			change_mode(mode_start)
		end
		update_camera()

	elseif game_mode==mode_start then
		update_player()
		update_camera()
	
	elseif game_mode==mode_play then
		if ticks%100==0 then
			new_enemy_group()
		end
		update_enemies()
		update_player()
		update_projectiles()
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


function parse_rect(r)
	local new_rect = {
		x1=r.x,
		y1=r.y,
		x2=r.x+r.width-1,
		y2=r.y+r.height-1,
	}
	if r.position~=nil then
		if r.position==down then
			new_rect.y1=new_rect.y1+r.height/2-1
		end
	end
	return new_rect
end


function collision(r1,r2)
	local rect1=parse_rect(r1)
	local rect2=parse_rect(r2)
	return rect1.x1<rect2.x2 and
  rect1.x2>rect2.x1 and
  rect1.y1<rect2.y2 and
  rect1.y2>rect2.y1
end


function is_offscreen(r)
	local cx=get_camera_x()
	return 
			(r.direction==left and r.x<cx-r.width) or
			(r.direction==right and r.x>cx+127+r.width) or
			r.y>127
end


function debug(message)
	printh(message,"kungfu")
end


function draw_osd()
	local camera_x = get_camera_x()
	local camera_y = get_camera_y()
	local x=camera_x+5
	local y=camera_y+5
	rectfill(camera_x,camera_y,camera_x+128,camera_y+24,0)

	print("player:",x,y,8)
	if player.health>0 then
		rectfill(x+28,y,x+28+player.health,y+4,8)
	end

	print(" enemy:",x,y+8,9)
	rectfill(x+28,y+8,x+28+50,y+12,9)

	draw_osd_level(x+85,y)
	print("life:1",x+85,y+8,7)
	rectfill(camera_x,camera_y+105,camera_x+127,camera_y+127,0)

	--print(tostr(player.grabbed),camera_x,camera_y,7)
	--print(#projectiles,camera_x,camera_y+106,7)
	--print(player.health,camera_x,camera_y+106,7)
end


function draw_osd_level(x,y)
	for i=1,3 do
		local c=12
		if i==current_level then
			c=9
		end
		print("█",(i-1)*12+x,y,c)
		if i<3 then
			print("-",(i-1)*12+x+8,y,9)
		end
	end	
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
-->8
-- camera


function get_camera_x()
	return peek2(0x5f28)
end


function get_camera_y()
	return peek2(0x5f2a)
end


function update_camera()
	camera(player.x-60,baseline-66)
	local camera_x = peek2(0x5f28)
	if camera_x<0 then
		camera(0,baseline-66)
	elseif camera_x>384 then
		camera(384,baseline-66)
	end
end
-->8
-- enemies


function init_enemies()
	enemies={}
	enemy_counter=0
	enemy_group_counter=0
	grab_guy=0
	knife_guy=1
	small_guy=2
end


function draw_enemies()
	for enemy in all(enemies) do
		spr(enemy.sprite,enemy.x,enemy.y,enemy.size,enemy.size,enemy.flip_x)
	end
end


function new_enemy(kind,stagger)
	local camera_x = get_camera_x()
	local direction=flr(rnd(2))
	enemy={
		kind=kind,
		y=baseline,
		w_index=0,
		health=1,
		speed=1.5,
		grabbing=false,
		dead=false,
		size=2,
		knife=false,
		facing=direction,
		idle=0,
		throwing=0,
		attack_height=up,
		cooldown=0,
		width=8,
		height=16,
	}
	if direction>0 then
		enemy.direction=right
	else
		enemy.direction=left
	end
	if enemy.kind==knife_guy then
		enemy.health=2
	elseif enemy.kind==small_guy then
		enemy.y+=8
		enemy.height=8
	end
	if enemy.direction==left then
		enemy.x=player.x+64+stagger
	else
		enemy.x=player.x-64-stagger
	end
	add(enemies,enemy)
end


function new_enemy_group()
	local total=3
	for i=1,total-1 do
		new_enemy(grab_guy,i*16)
	end
	if enemy_group_counter>2 then
		new_enemy(knife_guy,total*16)
		enemy_group_counter=0
	else
		new_enemy(grab_guy,total*16)
		enemy_group_counter+=1
	end
end


function update_enemies()

	for enemy in all(enemies) do
	
		enemy.x2=enemy.x+8*enemy.size
		enemy.y2=enemy.y+8*enemy.size

		if ticks%3==0 then
			enemy.w_index+=1
			if enemy.w_index>1 then
				enemy.w_index=0
			end
		end
		
		if collision(player.hitbox,enemy) and (player.punching>5 or player.kicking>5) then
			player.strike_hit=3
			enemy.health-=1
			sfx(-1)
			sfx(10)
		end
		
		if enemy.health<=0 then
			enemy.dead=true
		end
		
		if enemy.dead==true then
			if enemy.direction==right then
				enemy.x-=gravity/2
				enemy.y+=gravity
			else
				enemy.x+=gravity/2
				enemy.y+=gravity
			end
		end

		if enemy.kind==grab_guy then
			update_grab_guy(enemy)
			
		elseif enemy.kind==knife_guy then
			update_knife_guy(enemy)			
			
		elseif enemy.kind==small_guy then
			update_small_guy(enemy)	

		end
		
		enemy.flip_x=false
		if enemy.facing==left then
			enemy.flip_x=true
		end
		

		if is_offscreen(enemy) then
			del(enemies,enemy)
		end

	end

end


function update_grab_guy(enemy)
	enemy.sprite=100
	if enemy.dead==true then
		enemy.sprite=106
	elseif enemy.grabbing==true then
		enemy.sprite=104
	else
		enemy.sprite+=enemy.w_index*2
		if collision(enemy,player) then
			player.grabbed=5
			player.jump_dir=0
			enemy.grabbing=true
		else
			enemy.x+=enemy.direction*enemy.speed
			enemy.facing=enemy.direction
		end
	end
end


function update_knife_guy(enemy)

	local target=0
	local window=8	

	enemy.sprite=128
	enemy.facing=enemy.direction
	
	if enemy.dead==true then
		enemy.sprite=140
	elseif enemy.direction==right then
		target=player.x-32
	elseif enemy.direction==left then
		target=player.x+32
	end
	
	if enemy.throwing>0 then
		if enemy.throwing==1 then
			if enemy.attack_height==up then
				new_projectile(knife,enemy.x,player.y,2*enemy.direction,0)
				enemy.attack_height=down
				enemy.sprite=134
			else
				new_projectile(knife,enemy.x,player.y+8,2*enemy.direction,0)
				enemy.attack_height=up
				enemy.sprite=136
			end
			enemy.throwing-=1
		elseif enemy.throwing<8 then
			enemy.sprite=132
		elseif enemy.throwing<5 then
			enemy.sprite=134
		end
		enemy.throwing-=1
	elseif enemy.cooldown<1 then
		if enemy.x<target-8 then
			enemy.sprite+=enemy.w_index*2
			enemy.x+=enemy.speed
			enemy.facing=right
		elseif enemy.x>target+8 then
			enemy.sprite+=enemy.w_index*2
			enemy.x-=enemy.speed
			enemy.facing=left
		else
			enemy.throwing=10
			enemy.cooldown=50
		end
	else
		enemy.cooldown-=1
	end
	
end


function update_small_guy(enemy)
	enemy.sprite=108
	if enemy.dead==true then
		enemy.sprite=111
	elseif enemy.grabbing==true then
		enemy.sprite=110
	else
		enemy.sprite+=enemy.w_index*1
		if collision_narrow(enemy,player) then
			player.grabbed=10
			enemy.grabbing=true
		else
			if enemy.direction==right then
				enemy.x+=enemy.speed
			else
				enemy.x-=enemy.speed
			end				
		end
	end
end
-->8
-- levels

function init_levels()
	current_level=1
end

function draw_level()
	for i=0,63 do
		local x=i*8*4
		map(0,0,x,24,4,10)
	end
end
-->8
-- modes


function init_modes()
	mode_menu=0
	mode_intro=1
	mode_start=2
	mode_play=3
	mode_complete=4
	mode_death=5
	mode_gameover=6
	mode_win=7
	intro_timer=160
end


function change_mode(mode)
	game_mode=mode
	if game_mode==mode_intro then
		music(5)
	elseif game_mode==mode_start then
		init_enemies()
		init_player()
		init_projectiles()
		sfx(8)
	elseif game_mode==mode_play then
		music(0)
	elseif game_mode==mode_death then
		music(-1)	
	end
end
-->8

-->8
-- player


function init_player()
	player={
		x=64*8-16,
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
			width=4,
			height=4
		},
		sprite=0,
		grabbed=0,
		hold_time=6,
		health=50,
		strike_hit=0,
		width=8,
		height=16,
		hurt=0,
		jump_max=16,
		jump_dir=0,
	}
end


function draw_player()
	debug('draw player')
	spr(player.sprite,player.x,player.y,2,2,player.flip_x)	
	if player.strike_hit>0 then
		spr(68,player.hitbox.x-2,player.hitbox.y-2)
	end
	rectfill(player.hitbox.x,player.hitbox.y,player.hitbox.x+player.hitbox.width-1,player.hitbox.y+player.hitbox.height-1,10)
end


function get_player_input()
	if btn(⬅️) and player.jumping==0 then
		player.direction=left
	elseif btn(➡️) and player.jumping==0 then
		player.direction=right
	end
	if btn(⬇️) then
		player.position=down
	elseif player.punching==0 and player.kicking==0 then
		player.position=up
	end
	if btn(⬆️) then
		if player.btnup_down==false then
			if player.y==baseline then
				player.jumping=player.jump_max
			end
			player.jump_dir=0
			if btn(⬅️) then
				player.jump_dir=left
			elseif btn(➡️) then
				player.jump_dir=right
			end
		end
		player.btnup_down=true
	else
		player.btnup_down=false
	end
	if btn(4) and player.grabbed<1 then
		if player.btn4_down==false then
			player.kicking=10
			sfx(9)
		end
		player.btn4_down=true
	else
		player.btn4_down=false
	end
	if btn(5) and player.grabbed<1 then
		if player.btn5_down==false then
			player.punching=10
			sfx(9)
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
end


function update_player()

	if ticks%4==0 then
		player.w_index+=1
		if player.w_index>3 then
			player.w_index=0
		end
	end
	
	if game_mode==mode_start then
		player.walking=true
		player.x-=player.speed
		if player.x<64*8-1-56 then
			change_mode(mode_play)
		end
		
	elseif game_mode==mode_play then
		player.last_direction=player.direction
		get_player_input()
		if player.last_direction!=player.direction then
			player.grabbed-=1
			if player.grabbed<0 then
				player.grabbed=0
			end		
		end		
		if player.grabbed>1 then
				player.health-=0.5
		else
			for enemy in all(enemies) do
				if enemy.grabbing==true then
					enemy.dead=true
				end
			end
		end
		-- apply gravity/momentum
		if player.jumping>0 then
			player.x+=player.jump_dir*player.speed
		end
		if player.jumping>player.jump_max/2 then
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
		else
			player.hitbox.x=player.x
		end
		player.hitbox.position=player.position
		if player.jumping>0 and player.kicking>0 then
			player.hitbox.position=down
		end
		if player.hurt>0 then
			player.hurt-=1
		end		
		if player.health<=0 then
			change_mode(mode_death)
		end

	elseif game_mode==mode_death then
		if player.direction==left then
			player.x+=gravity/2
		else
			player.x-=gravity/2
		end
		player.y+=gravity
		if player.y>get_camera_y()+128 then
			change_mode(mode_start)
		end

	end
	
	update_player_sprite()

end


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
		elseif player.hurt>0 then
			player.sprite=36
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
-- projectiles


function init_projectiles()
	knife=0
	projectiles={}
end


function draw_projectiles()
	for projectile in all(projectiles) do
		spr(98,projectile.x,projectile.y,1,1,projectile.flip_x)
	end
end


function new_projectile(kind,x,y,xspeed,yspeed)
	projectile={
		kind=kind,
		x=x,
		y=y,
		xspeed=xspeed,
		yspeed=yspeed,
		size=1,
		width=7,
		height=3,
		direction=right,
	}
	if xspeed<0 then
		projectile.direction=left
	end
	add(projectiles,projectile)
end


function update_projectiles()
	for projectile in all(projectiles) do
		projectile.x+=projectile.xspeed
		projectile.y+=projectile.yspeed
		if kind==0 then
			projectile.sprite=98
		end
		projectile.flip_x=false
		if projectile.direction==left then
			projectile.flip_x=true
		end
		if collision(projectile,player) then
			player.hurt=5
			player.health-=10
			del(projectiles,projectile)
		elseif	is_offscreen(projectile) then
			del(projectiles,projectile)
		end
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
ccccc776677cccccccccccc777ccccccccccc777c77cccccccccc7777c99cccccccccccc77ccccccccccc777ccc77cccccccc777ccc77cccccccc998798ccccc
cccc777cc777cccccccccc777ccccccccccc777cc777cccccccc0977cc000ccccccccccc777ccccccccc777ccc777ccccccc777ccc777ccccccc77977777cccc
ccc099cccc99cccccccccc99ccccccccccc099cccc99cccccccc09ccccccccccccccccccc99ccccccccc99cccc99cccccccc99cccc99cccccccc997cc799cccc
ccc0000ccc000ccccccccc000cccccccccc0000ccc000ccccccc0ccccccccccccccccccc000ccccccccc000ccc000ccccccc000ccc000cccccc000cccc000ccc
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
ccccccccbbbbbb3688888888888a8888c9cccccccccccccc00990099009900990099999000099999000000000999999009900990ccc77ccccccccaa3333c38cc
ccccccccbbbbb36baaaaa8aaaa8a8aaaccacccc9cccc33cc08990899089908990899999900999999000000008999999089908990cc7dd7ccccccc833883833cc
ccccccccbbbb36bbccccc8a88a8a8a88ccc7ccacccc3333c08999999089908990899889908998880000000008998880089908990cc7777cccccc8c833333c7cc
ccccccccbbb36bbbccccc8a8888a8888ccccc7ccccc37ccc08999990089908990899089908990000000000008999999089908990ccc7dcccccccc8c83ac7cccc
ccccccccbb36bbbbccccc8aaaa8a8aaacc7ccccccccc37cc08999990089908990899089908990099000000008999999089908990ccd777ccccccccc83aaccccc
ccccccccb36bbbbbccccc888888a8888cacc7ccccc88c37c08998899089999990899089908999999000000008998880089999990cc7dd7cccccccc8c83baaccc
cccccccc33333333cccccccccc8a8ccc9ccccaccc833837c08990899089999900899089908999999000000008990000089999900cc7777ccccccccccc333bacc
cccccccc00000000cccccccccc8a8ccccccccc9c83c337cc08800880088888000880088008888880000000008880000088888000ccc7dcccccccccccc8383bac
ffffffff7ccccccccccccccccc8a8ccccccaacccccccccccccccccccccffffccccffeecccccc7cccccccc8ccccccccccccd77cccccc77ccccccccccccc383bac
4444444467cccccccccccccccc8a8ccccca33acccccc33cccccccccccbffff8ccfeeffecc77cc77ccc888aacc8888ccccc7dd7cccc7dd7cccccccc8cc833bbac
ffffffffc67cccccaaaaaaaaaaaaaaaaccbaabccccc3333cccccc8ccfbbff88feeffeeffc7fcff7cc8aaa777cc9998cccc7777cccc7777cccccc8c8ccc3bbacc
ffffffffc444ffff8888888888888888ca3bb3acccc377ccbcc8cccbffbb88ffeeffeeff7ccccfcc8a77778ccc9198ccccd7ddccccc7dcccccccc8a8c3bbaccc
44444444ccc555ccaaaaaaaaaaaaaaaacba33abccccc337cc8cccc8cfff88fffffeeffeeccfcccc7c8aaa777cc9999ccccd777ccccd777ccccc88aa338bacccc
ffffffffcccc67ccccccccccccccccccc3baab3ccccccc37cb3cc3bcff88bbffffeeffeec7ffcf7ccc888aacccc998cccc7dd7cccc7dd7ccccccc8333baccccc
ffffffffccccc67ccccccccccccccccccc3bb3ccc8888c373c8338c3c88ffbbcceffeefcc77cc77cccccc8cccccccccccc7777cccc7777cccccccccc3acccccc
ffffffffcccccc67ccccccccccccccccccc33ccc83c3337cc3b88b3cccffffcccceeffccccc7ccccccccccccccccccccccc7ddccccc7dccccccccccccccccccc
4444444444444444cccccccc88888888ccccccc2222cccccccccccc2222cccccccccccc2222cccccccccccccccccccccccc444ccccc444ccccc444cc4ccccccc
8888888888888888cccccccca8aaaaaacccccc2999cccccccccccc2999cccccccccccc2999cccccccccccccccccccccccc499ccccc499ccccc499ccc499cc9cc
8aaaaaa88aaaaaa8cc1ccccca8cccccccccccc2929cccccccccccc2929cccccccccccc2929cccccccc4cccccccccccccccc99cccccc99cccccc99cccc4983ccc
8a8888a88a8888a844177777a8cccccccccccc9999cccccccccccc9999cccccccccccc9999ccccccc499ccccc99ccccccc388cccccc38cccccc83ccccc388ccc
8a8aaaa88aaaa8a84417777ca8cccccccccccc299ccccccccccccc299ccccccccccccc299cccccccc4999cccc99ccccccc3989ccccc38cccccc8839cc3c8833c
8a888888888888a8cc1ccccc88ccccccccccc2f222cccccccccccff22fccccccccccccff22ccccccc4499cffffccccccccc33cccccc93ccccccc3ccc9ccc3c3c
8aaaaaaaaaaaaaa8cccccccccccccccccccccfff22ccccccccccfff222fcccccccccccff22cccccccc42222ffccccccccc3cc3ccccc3ccccccc3cccccccc3c88
8888888888888888cccccccccccccccccccccfff2299ccccccccff2222fcccccccccccfff299ccccccff2222cccccccccc88c88cccc88cccccc88ccccccc88cc
111111111122221188888888ccccccccccccccf99299ccccccccff2222f99ccccccccccfff9cccccccff2222ffcccccccccccccccccccccccccccccccccccccc
11111111118e8811aaaaaaaaccccccccccccccf99fccccccccccf9922cc99cccccccccc2ff99ccccccff222ffffcccccccc44ccccc88cccccc8833cccccccccc
1c1c1c1c118e8811ccccccccaaaaaaaacccccccfffccccccccccc99fffcccccccccccccfffccccccccffc2fff2fccccccc4994ccc38884ccccc3888ccc4c3c8c
c1c1c1c1c18e8811cccccccc88888888cccccccfffccccccccccccfffffccccccccccccfffcccccccccf99ff2ffccccccc833cccc388394ccc33888cc493338c
1ccc1ccc17888871ccccccccaaaaaaaaccccccffffcccccccccccffffffcccccccccccffffcccccccccc99ff29ffccccc88833ccc833394cccc338ccc493883c
cc1ccc1c11777711ccccccccccccc67cccccc29ffcccccccccccfffccfffccccccccccfffccccccccccccccc29fffcccc8883cccc8c3c4cccc4994cccc48883c
ccccccccc111111ccccccccccccccc67ccccc29cccccccccccc299cccc99cccccccccc299ccccccccccccccc2cf299cccc3388ccccccccccccc44ccccccc88cc
ccccccccccccccccccccccccccccccc6ccccc222ccccccccccc2222ccc222ccccccccc2222ccccccccccccccccc2222ccccccccccccccccccccccccccccccccc
ccccccc1111cccccccccccc1111ccccc777199c1111cccccccccccc1111cccccccccccc1111cccccccccccccccccccccccccccccccccccccccccccc77ccccccc
cccccc7777cccccccccccc7777cccccccc71997777cccccccccc7c7777cccccccccccc7777cccccccccccccc1111cccccccccccccccccccccccccc7777cccccc
ccccc71919ccccccccccc71919ccccccccc1c71919ccccccccccc71919ccccccccccc71919ccccccccccc7c7777cccccccc1cccccccccccccccc776777776ccc
cccccc9999cccccccccc7c9999ccccccccccc79999cccccccccccc9999ccccccccccc79999cccccccccccc71919ccccccc177ccccc99cccccccc67777776cccc
cccccc199ccccccccccccc199cccccccccccc7199ccccccccccccc199cccccccccccc7199cccccccccccccc9999ccccccc7999cccc99cccccc7cc6777667cccc
ccccc77117ccccccccccc17111ccccccccccc11111ccccccccccc7711777799cccccc11111ccccccccccccc199cccccccc7199c7777ccccccc677777677776cc
cccc7771117cccccccccc77711ccccccccccc17711cccccccccc7771117779ccccccc17711ccccccccccc77111ccccccc7c1111177ccccccccc6777777776ccc
cccc7711117cccccccccc7771199ccccccccc1777799cccccccc7711117ccccccccc71777799cccccccc7771117cccccccc771111ccccccccccc67777676cccc
cccc771111799ccccccccc799199cccccccccc177799cccccccc771111cccccc777191177799cccccccc77111177ccccccc77111177ccccccccc67766766cccc
cccc79911cc99ccccccccc7997cccccccccccc1111cccccccccc79911ccccccccc71991111cccccccccc79911cc799ccccc771117777cccccccc7677777ccccc
ccccc99777ccccccccccccc777ccccccccccccc777ccccccccccc997777cccccccc1ccc777ccccccccccc997777c99ccccc77c777717ccccccc777677777cccc
cccccc77777cccccccccccc777ccccccccccccc777cccccccccccc777777ccccccccccc777cccccccccccc777777cccccccc79977177cccccccc77677677cccc
ccccc777777ccccccccccc7777cccccccccccc7777ccccccccccc777c777cccccccccc7777ccccccccccc777c777ccccccccc99771977ccccccc67777776cccc
cccc777cc777ccccccccc1977cccccccccccc1977ccccccccccc777ccc77ccccccccc1977ccccccccccc777ccc77ccccccccccccc19777ccccccc677776ccccc
ccc199cccc99ccccccccc19cccccccccccccc19cccccccccccc199ccc199ccccccccc19cccccccccccc199ccc199ccccccccccccc1c7199ccccccc6776cccccc
ccc1111ccc111cccccccc111ccccccccccccc111ccccccccccc1111ccc111cccccccc111ccccccccccc1111ccc111ccccccccccccccc1111ccccccc66ccccccc
cccccccc4444cccccccccccc4444cccc4444499c4444cccccccccccc4444cccccccc4ccccccccccccccccccccccccccccccccccccccccccc0000000000000000
ccccccc4999cccccccccccc4999cccccccccc994999cccccccccccc4999cccccccccc4cccccccccccccccccccccccccccccccccccccccccc0000000000000000
ccccccc4919cccccccccccc4919ccccccccccc64919cccccccccccc4919ccccccccccc4cccccccccccccccccccccccccccc4cccccccccccc0000000000000000
ccccccc9999cccccccccccc9999ccccccccccc69999cccccccccccc9999cc99cccccccc4c4444cccccccccccc4444ccccc499ccccc99cccc0000000000000000
ccccccc499ccccccccccccc499cccccccccccc6499ccccccccccccc499cc699cccccccc94999cccccccccccc4999cccccc4999cccc99cccc0000000000000000
cccccc66446ccccccccccc46444ccccccccccc44444ccccccccccc66446666ccccccccc949196ccccccccccc4919cccccc4499c6666ccccc0000000000000000
ccccc6664446cccccccccc66644ccccccccccc46644cccccccccc66644466ccccccccccc99996ccccccccccc9999ccccccc4444466cccccc0000000000000000
ccccc6644446cccccccccc6664499ccccccccc4666699cccccccc6644446cccccccccccc49966ccccccccccc499cccccccc664444ccccccc0000000000000000
ccccc664444699ccccccccc699499cccccccccc466699cccccccc664444ccccccccccc664446cccccccccc6644466699ccc66444466ccccc0000000000000000
ccccc69944cc99ccccccccc6996cccccccccccc4444cccccccccc69944ccccccccccc666444cccccccccc6664446669cccc664446666cccc0000000000000000
cccccc99666ccccccccccccc666ccccccccccccc666ccccccccccc996666ccccccccc6644466ccccccccc6644466ccccccc66c666646cccc0000000000000000
ccccccc66666cccccccccccc666ccccccccccccc666cccccccccccc666666cccccccc69946666cccccccc69946666ccccccc69966466cccc0000000000000000
cccccc666666ccccccccccc6666cccccccccccc6666ccccccccccc666c666ccccccccc9966666ccccccccc9966666cccccccc99664966ccc0000000000000000
ccccc666cc666ccccccccc4966cccccccccccc4966ccccccccccc666ccc66cccccccc6666cc66cccccccc6666cc66cccccccccccc49666cc0000000000000000
cccc499cccc99ccccccccc49cccccccccccccc49cccccccccccc499ccc499ccccccc499ccc499ccccccc499ccc499cccccccccccc4c6499c0000000000000000
cccc4444ccc444cccccccc444ccccccccccccc444ccccccccccc4444ccc444cccccc4444ccc444cccccc4444ccc444cccccccccccccc44440000000000000000
ccccccc4444cccccccccccc4444cccccccccccc4444ccccccccccccccccccccccccccc4444cccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccc4999cccccccccccc4999cccccccccccc4999cccccccccccc4444ccccccccccc4999cccccccccccccc4444cccccccccccccc4444ccccccccccccccccccc
cccccc4939cccccccccccc4939cccccccccccc4939ccccccccccc4999cccccccccccc4939ccccccccccccc4999cccccccccccccc4999cccccccccccccccccccc
cccccc9999cccccccccccc9999cccccccccccc9999ccccccccccc4939ccccccccccccc999ccccccccccccc4939cccccccccccccc4939cccccccccccccccccccc
cccccc099ccccccccccccc099cccccccccccccc99cccccccccccc4999cc9ccccccccc099ccccc088ccccccc999cc9cccccccccccc999ccccccccccc4444ccccc
ccccc88008ccccccccccc08800cccccccccccc0088ccccccccccc0000cc9cccccccc008908cc0098cccccc88009c9ccccccccccc80088999cccccc4999cccccc
cccc888800ccccccccccc88800cccccccccccc0888cccccccccc88090899ccccccc8880880800098ccccc08889989cccccccccc8008889c9cccccc4939cccccc
cccc9880008cccccccccc8890ccccccccccccc0889cccccccccc8899889cccccccc8880098800cccccccc08999899cccccccccc80088ccccccccccc999cccccc
cccc99000c99ccccccccc89988cccccccccccc08999ccccccccc899880cccccccccc89999808cccccccccc0099cccccccccccccc0000ccccccccc88098cccccc
ccccc9988cc99ccccccccc99808ccccccccccc888999ccccccccc980080cccccccccc999800cccccccccccc8888cccccccccccc8888ccccccccc8800008ccccc
ccccc09908ccccccccccccc990cccccccccccc0000cccccccccccc000000ccccccccccc000ccccccccccccc00808ccccccccccc00000cccccccc8800008ccccc
cccccc50000cccccccccccc000cccccccccccc00000ccccccccccc000c00ccccccccccc000cccccccccccc000c000ccccccccc000c000ccccccc9988899ccccc
ccccc005500ccccccccccc0000ccccccccccc000c00cccccccccc0000c99cccccccccccc00ccccccccccc000ccc00cccccccc000ccc00cccccccc998098ccccc
cccc000cc000ccccccccc8900ccccccccccc000cc000cccccccc8900cc888ccccccccccc000ccccccccc000ccc000ccccccc000ccc000ccccccc00900000cccc
ccc899cccc99ccccccccc89cccccccccccc899cccc99cccccccc89ccccccccccccccccccc99ccccccccc99cccc99cccccccc99cccc99cccccccc990cc099cccc
ccc8888ccc888cccccccc8ccccccccccccc8888ccc888ccccccc8ccccccccccccccccccc888ccccccccc888ccc888ccccccc888ccc888cccccc888cccc888ccc
ccccccccccccccccccccccccccccccccccccccccccccccccccccccc4444cccccccccccccc4444cccccccccccccccccccccccccc4444ccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccc44ccccccccccccc4999cccccccccccccc4999cccccccccccccccccccccccccc4999cccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccc4494cccccccccccc4939cccccccccccccc4939cccccccccccccccccccccccccc4939ccccccccc4cccccccccccc
ccccccccccccccccccccccccc4444ccccccccc4999cccccccccccc9999ccccccccccccccc999cccccccccccccccccccccccccc9999cccccccc499ccccc99cccc
ccccccc4444ccccccccccccc4999cccccccccc099ccccccccccccc099cccccc8cccccccc80088999ccccccc4444ccccccccccc099ccccccccc4999cccc99cccc
cccccc4999cccccccccccccc4939ccccccccc88008ccccccccccc08000cccc98ccccccc8008889c9cccccc4999ccccccccccc08000cccccccc4499c8899ccccc
cccccc4939ccccccccccccccc999cccccccc8880089cccccccccc880908cc098ccccccc80088cccccccccc4939ccccccccccc88090ccccccccc8000089cccccc
ccccccc999cc9ccccccccccc80088999cccc98800099ccccccccc8899880000ccccccccc0000ccccccccccc999ccccccccccc889988cccccccc888000ccccccc
cccccc88009c9cccccccccc8008889c9ccc998888cc99cccccccc899880800ccccccccc8888cccccccccc88098ccccccccccc8998800ccccccc88800800ccccc
ccccc08889989cccccccccc80088ccccccc9cc0808c99ccccccccc980000ccccccccccc00000cccccccc8800008ccccccccccc9800800cccccc880080000cccc
ccccc08999899ccccccccccc0000ccccccc99c000cccccccccccccc0000ccccccccccc000000cccccccc8800008cccccccccccc000000cccccc99c800050cccc
cccccc889980ccccccccccc8888cccccccccccc000cccccccccccccc000ccccccccccc000899cccccccc9988899cccccccccccc000899ccccccc99900800cccc
cccccc0000080ccccccccc0000080cccccccccc000cccccccccccc0000ccccccccccc0000c888cccccccc9980980cccccccccc0000c888ccccccc99c08900ccc
cccc90000c000ccccccc90000c000ccccccccc890cccccccccccc890cccccccccccc8900cccccccccccc0090000000ccccccc8900cccccccccccccccc89000cc
ccc89000ccc99cccccc89000ccc99cccccccccc89cccccccccccc89ccccccccccccc89cccccccccccccc990cccc00998ccccc89cccccccccccccccccc8c0899c
ccc88cccccc888ccccc88cccccc888cccccccccc88ccccccccccc8cccccccccccccc8cccccccccccccc888ccccccc888ccccc8cccccccccccccccccccccc8888
__gff__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001010101010000000000000000000002010101010000000000000000000000000101010100000000000000000000000001010101000000000000000002020202
0000000000000000000000000000020000000000000000000000000000000200020202020202020202020202020202000202020202020202020202020002020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
41414141414141414a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a
42436372424363724a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a
52535252525352524a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a
40404040404040404a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a
40404040404040404a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a
40404040404040404a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a
40404040404040404a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a
50505050505050504a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a
60616061616061604a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a
71707070414141414a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a
4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a
4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a
4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a
4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a
4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a
4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a
4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a
4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a
4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a
4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a
4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a
4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a
4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a
4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a
4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a
4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a
4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a
4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a
4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a
4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a
__sfx__
010c0000073250030507325053250732500305073250532507325003050732505325073250a3250732505325073250030507325053250732500305073250532507325003050732505325073250a3250732505325
010c00000c325003050c3250a3250c325003050c3250a3250c325003050c3250a3250c3250f3250c3250a3250c325003050c3250a3250c325003050c3250a3250c325003050c3250a3250c3250f3250c3250a325
010c00000e325000000e3250c3250e325000000e3250c3250e325000000e3250c3250e325113250e3250c3250c325000000c3250a3250c325000000c3250a3250c325000000c3250a3250c3250f3250c3250a325
010c00000062500005006250062500625000050062500625006250000500625006250062500005006250062500625000050062500625006250000500625006250062500005006250062500625000050062500625
011000001a430184301543013430114300e430114300e4000e4000e4300e400004001a430184301543013430114300e4301143000400004000e43000400004001a430184301543013430114300e4301143000400
01100000004000e43000400004000c4300e4000e43000400004000040000400004000040000400004000040000400004000040000400004000040000400004000040000400004000040000400004000040000400
011000001f4301d4301a4301843016430134301643013400074001343000400004001f4301d4301a4301843016430134301643000400004001343000400004001f4301d4301a4301843016430134301643000400
011000000040013430004000040011430004001343000400004000040000400004000040000400004000040000400004000040000400004000040000400004000040000400004000040000400004000040000400
01060000136452560003645216001364518600036450f600136452560003645216001364518600036450f600136452560003645216001364518600036450f600136452560003645216001364518600036450f600
010800003167424674006040060400604006040060400604006040060400604006040060400604006040060400604006040060400604006040060400604006040060400604006040060400604006040060400604
010c00002867500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005
__music__
01 00034344
00 00034344
00 01034344
00 00034344
02 02034344
01 04064844
00 05074844

