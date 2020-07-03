pico-8 cartridge // http://www.pico-8.com
version 27
__lua__
-- ===================
-- kung fu
-- andrew stephens
-- june 2020
-- version 0.1
-- ===================


debug=true
skip_intro=true
test_mode=true
onscreen_debug=false
logfile="kungfu"

palt(0,false)
palt(12,true)

left=-1
right=1
up=-1
down=1
high=1
low=0
baseline=65
gravity=2
ticks=0
mode_menu=0
mode_intro=1
mode_start=2
mode_play=3
mode_complete=4
mode_death=5
mode_gameover=6
mode_win=7
level_size=128
first_run=true
min_x=0
max_x=level_size*8-1


current_level=1

function _init()
	
	if debug then
			poke(0x5f2d,1)
	end
	
	init_player()
	init_enemies()
	
	change_mode(mode_menu)
	printh("kungfu.p8 log",logfile,true)

end

function _update()
	ticks=ticks+1
	if game_mode==mode_menu then
		mode_menu_update()
	elseif game_mode==mode_intro then
		mode_intro_update()
	elseif game_mode==mode_start then
		mode_start_update()
	elseif game_mode==mode_play then
		mode_play_update()
	elseif game_mode==mode_death then
		mode_death_update()
	elseif game_mode==mode_complete then
		mode_complete_update()
	elseif game_mode==mode_tally then
		mode_tally_update()
	end
	last_time=current_time
end

function _draw()	
	if game_mode==mode_menu then
		mode_menu_draw()
	elseif game_mode==mode_intro then
		mode_intro_draw()
	elseif game_mode==mode_start then
		mode_start_draw()
	elseif game_mode==mode_play then
		mode_play_draw()
	elseif game_mode==mode_death then
		mode_death_draw()
	elseif game_mode==mode_complete then
		mode_complete_draw()
	end
	if test_mode then
		local x=camera_x
		local y=camera_y
		print('test mode',x,y,7)
		draw_osd_debug()
	end
end

function change_mode(mode)
	game_mode=mode
	if game_mode==mode_intro then
		mode_intro_init()
	elseif game_mode==mode_start then
		mode_start_init()
	elseif game_mode==mode_play then
		mode_play_init()
	elseif game_mode==mode_death then
		mode_death_init()
	elseif game_mode==mode_complete then
		mode_complete_init()
	elseif game_mode==mode_tally then
		mode_tally_init()
	end
end

function center_print(text,xc,y,c)
	local w=#text*4
	local x=xc-w/2-4
	rectfill(x-1,y-1,x+w-1,y+5,0)
	print(text,x,y,c)
end



-- ================
-- levels
-- ================

function draw_level()
	-- draw level
	for i=-6,level_size/4+6 do
		local x=i*8*4
		map(0,0,x,24,4,10)
	end
	-- draw stairs
	for i=0,5 do
		if current_level%2==0 then
			spr(81,max_x+48-i*8,33+i*8,1,1,true)
		else
			spr(81,-48+i*8,33+i*8,1,1)
		end
	end
	-- draw boss thresholds
	spr(192,min_x+boss_threshold,baseline)
	spr(192,max_x-boss_threshold,baseline)
end

function is_offscreen(r)
	local cx=camera_x
	return 
			(r.direction==left and r.x<cx-r.tile_width*8) or
			(r.direction==right and r.x>cx+127+r.tile_width*8) or
			r.y>127
end

-- ===================
-- on screen display
-- ===================

function draw_osd()

	function draw_osd_enemy(x,y)
		function get_boss()
			for enemy in all(enemies) do
				if enemy.boss then
					return enemy
				end
			end
			return nil
		end
		local boss=get_boss()
		local health=50
		if boss~=nil then
			health=boss.health
		end
		print(" enemy:",x,y+8,9)
		rectfill(x+28,y+8,x+28+health/3,y+12,9)
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
	
	function draw_osd_player(x,y)
		print("p:",x,y,8)
		health_bar(x,y)
		if player.health>0 then
			--rectfill(x+28,y,x+28+player.health/3,y+4,8)
		end
	end	

	function health_bar(x,y,decimal,c)
		rectfill(x,y,x+15,y+4,12)
		local amount=decimal*15
		rectfill(x,y,x+amount,y+4,c)
	end

	local x=camera_x+5
	local y=camera_y+5

	rectfill(camera_x,camera_y,camera_x+128,camera_y+24,0)

	print('player',x,y,9)
	health_bar(x+25,y,player.health/100,9)
	
	print(' enemy',x,y+8,8)
	health_bar(x+25,y+8,1,8)
	

	--draw_osd_enemy(x,y)
	--draw_osd_player(x,y)
	draw_osd_level(x+50,y)

	print("life:1",x+55,y+8,7)
	print("000000",x+91,y,7)
	print("time:"..flr(level_timer),x+85,y+8,7)

	rectfill(camera_x,camera_y+105,camera_x+127,camera_y+127,0)


end

-- ===================
-- projectiles
-- ===================

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
		body={
			x=x,
			y=y,
			width=4,
			height=4
		},
		tile_width=1,
		tile_height=1,
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
		projectile.body.x=projectile.x
		projectile.body.y=projectile.y
		if collision(projectile.body,player.body) then
			player.hurt=5
			player.health-=10
			del(projectiles,projectile)
		elseif	is_offscreen(projectile) then
			del(projectiles,projectile)
		end
	end	
end

-- -------
-- effects
-- -------

function init_effects()
	effects={}
	enemy_hit_effect=0
	player_hit_effect=0
end

function new_effect(kind,x,y)
	local effect={
		kind=kind,
		x=x,
		y=y,
		countdown=3,
	}
	add(effects,effect)
end

function update_effects()
	for effect in all(effects) do
		effect.countdown-=1
		if effect.countdown<1 then
			del(effects,effect)
		end
	end
end

function draw_effects()
	for effect in all(effects) do
		local c
		if effect.kind==enemy_hit_effect then
			c=7
		else
			c=8
		end
		print("✽",effect.x,effect.y,c)		
	end
end

-- ===================
-- scores
-- ===================

function init_scores()
	scores={}
end

function draw_scores()
 for score in all(scores) do
 	spr(91,x,y,1,1)
		print(score.n,score.x,score.y,7)
 end
end

function new_score(x,y,n)
	local score={
		x=x,
		y=y,
		n=n,
		count=10
	}
	add(scores,score)
end

function update_scores()
	for score in all(scores) do
		score.count-=1
		if score.count<1 then
 		del(scores,score)
 	end
	end
end

-- ===================
-- testing
-- ===================

function debug(message)
	printh(message,"kungfu")
end


function draw_osd_debug()

	function debug_print(label,var)
		color(7)
		if var~=nil then
			local text=label..':'..var
			print(text)
		end		
	end
		
	local x=0
	local y=0
	if camera_x~=nil then
		x=camera_x
	end
	if camera_y~=nil then
		y=camera_y
	end

	cursor(x,y)
	
	rectfill(x,y+90,x+127,y+127,0)

	cursor(x,y+91)
	debug_print('game_mode',game_mode)
	debug_print('camera_x',camera_x)
	debug_print('camera_y',camera_y)
	debug_print('enemies',#enemies)
	
	if player~=nil then
		cursor(x+64,y+91)
		debug_print('player.x',player.x)
		debug_print('player.y',player.y)
		if player.jumping>0 then
			debug_print('jumping',player.jumping)
		end
		if player.punching>0 then
			debug_print('punching',player.punching)
		end
		if player.kicking>0 then
			debug_print('kicking',player.kicking)
		end
	end
	
end

function test_input()
	local key=stat(31)
	if game_mode==mode_play then
		if key=="1" then
			new_enemy(0,random_enemy_x(0))
		elseif key=="2" then
			new_enemy(1,random_enemy_x(0))
		elseif key=="3" then
			new_enemy(2,random_enemy_x(0))
		elseif key=="4" then
			new_enemy(3,random_enemy_x(0))
			enemies[#enemies].active=true
		end
	end
end

-- ============
-- menu program
-- ============

function mode_menu_update()
	if btn(4) and btn(5) then
		if skip_intro then
			change_mode(mode_start)
		else
			change_mode(mode_intro)
		end
	end
end

-- draw sprite of string rows
function str_spr(str,sx,sy)
	local y=sy
	for row in all(str) do
		for i=1,#row do
			local x=sx+i-1
			local c=tonum(sub(row,i,i))
			pset(x,y,c)
		end
		y+=1
	end
end

function mode_menu_draw()
	local title_spr={
		'00990099009900990099999000099999000000000999999009900990',
		'08990899089908990899999900999999000000008999999089908990',
		'08999999089908990899889908998880000000008998880089908990',
		'08999990089908990899089908990000000000008999999089908990',
		'08999990089908990899089908990099000000008999999089908990',
		'08998899089999990899089908999999000000008998880089999990',
		'08990899089999900899089908999999000000008990000089999900',
		'08800880088888000880088008888880000000008880000088888000',
	}
	cls(0)
	local y=32
	for i=0,112,16 do
		spr(96,i,y)
		spr(96,i,y+20)
		spr(97,i+8,y)
		spr(97,i+8,y+20)
	end
	--spr(70,64-7*8/2,y+10,7,1)
	cursor(64-7*8/2,y+10)
	color(7)
	str_spr(title_spr,64-7*8/2,y+10)
	
	center_print("press 🅾️+❎ to start",64,y+40,7)
	spr(78,5,68,2,2)
	spr(78,106,68,2,2,true)
end

-- =============
-- intro program
-- =============

function mode_intro_init()
	--init_player()
	intro_timer=160
	update_camera()
	music(5)
end

function mode_intro_update()
	intro_timer-=1
	update_player()
	--update_player()
	--update_camera()
	if intro_timer<0 then
		change_mode(mode_start)
	end
end

function mode_intro_draw()
	cls(12)
	draw_level()
	draw_player()
	camera(camera_x,camera_y)
	local xc=camera_x+64
	center_print("level "..current_level,xc,50,7,true)
	draw_osd()
end

-- =============
-- start program
-- =============

function mode_start_init()
	level_timer=2000
	init_player()
	init_enemies()
	init_projectiles()
	init_scores()
	update_camera()
	start_timer=56
	sfx(8)
end

function mode_start_update()
	update_player()
	start_timer-=1
	if start_timer<1 then
		change_mode(mode_play)
	end
end

function mode_start_draw()
	cls(12)
	draw_level()
	draw_player()
	update_camera()
	local xc=camera_x+64
	center_print("level "..current_level,xc,50,7,true)
	draw_osd()
end

-- ===================
-- play (main) program
-- ===================

function mode_play_init()
	music(0)
	if current_level==1 then
		new_enemy(stick_guy,min_x)
	end
	init_effects()
end

function mode_play_update()
	update_effects()
	update_enemies()
	update_player()
	update_projectiles()
	update_scores()
	update_camera()
	if test_mode then
		test_input()
	end
	level_timer-=0.5
end

function mode_play_draw()
	cls(12)
	draw_level()
	draw_projectiles()
	draw_player()
	draw_enemies()
	draw_effects()
	draw_scores()
	draw_osd()
end

-- =============
-- death program
-- =============

function mode_death_init()
	music(-1)
end

function mode_death_update()
	update_player()
end

function mode_death_draw()
	cls(12)
	draw_level()
	draw_projectiles()
	draw_player()
	draw_enemies()
	draw_scores()
	draw_effects()
	draw_osd()
end

-- ======================
-- complete level program
-- ======================

function mode_complete_init()
	music(-1)
	if current_level%2==1 then
		complete_x=0
		complete_direction=left
	else
		complete_x=max_x-128
		complete_direction=right
	end
	complete_timer=0
	player.walking=false
end

function mode_complete_update()
	
	if complete_timer<=48 then
		complete_x+=complete_direction
	else
		player.x+=complete_direction
		player.y-=1
		update_player()
	end

	if complete_timer>100 then
		change_mode(mode_tally)
	end
	
	update_player()
	update_camera(complete_x,camera_y)
	
	complete_timer+=1

end

function mode_complete_draw()
	cls(12)
	draw_level()
	draw_player()
	draw_osd()
end

-- --------------
-- tally program
-- --------------

function mode_tally_init()
	current_level+=1
	change_mode(mode_start)
end

function mode_tally_update()
end

function mode_tally_draw()
end

-- =================
-- game over program
-- =================

-- ================
-- game win program
-- ================

-- ===================
-- camera
-- ===================

function update_camera(x,y)
	camera_x=player.x-56	
	camera_y=baseline-66
	if camera_x<min_x then
		camera_x=min_x
	elseif camera_x>max_x-127 then
		camera_x=max_x-127
	end	
	-- manual override
	if x~=nil then
		camera_x=x
	end
	if y~=nil then
		camera_y=y
	end
	camera(camera_x,camera_y)
end

-------------
-- collisions
-------------

function collision(r1,r2)
	function parse_rect(r)
		return {
			x1=r.x,
			y1=r.y,
			x2=r.x+r.width-1,
			y2=r.y+r.height-1,
		}
	end
	local rect1=parse_rect(r1)
	local rect2=parse_rect(r2)
	return rect1.x1<rect2.x2 and
  rect1.x2>rect2.x1 and
  rect1.y1<rect2.y2 and
  rect1.y2>rect2.y1
end


-->8
-- ===================
-- player
-- ===================

function init_player()
	player={
		score=0,
		x=0,
		y=baseline,
		walking=false,
		w_index=0,
		direction=right,
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
		body={
			x=0,
			y=0,
			width=8,
			height=16
		},
		hitbox={
			x=0,
			y=0,
			width=4,
			height=4
		},
		sprite=0,
		grabbed=0,
		hold_time=6,
		health=100,
		strike_hit=0,
		width=8,
		height=16,
		hurt=0,
		jump_max=15,
		jump_dir=0,
		tile_size=2,
	}
	if current_level%2==1 then
		player.x=max_x-16
		player.direction=left
	end
end

function update_player()
	if ticks%4==0 then
		player.w_index+=1
		if player.w_index>1 then
			player.w_index=0
		end
	end	
	if game_mode==mode_start then
		player.walking=true
		player.x+=player.speed*player.direction
	elseif game_mode==mode_play then
		player.last_direction=player.direction
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
		if btn(⬆️) and player.grabbed==0 then
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
					enemy.shook=true
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
		player.body.x=player.x+4
		player.body.y=player.y
		player.body.height=16
		if player.position==down then
			player.body.y+=8
			player.body.height=8
		end
		-- update the hitbox
		player.hitbox.width=4
		player.hitbox.height=4
		if player.direction==right then
			player.hitbox.x=player.x+15
		else
			player.hitbox.x=player.x-4
		end
		player.hitbox.y=player.y
		if player.jumping>0 then
			if player.kicking>0 then
				player.hitbox.y+=8
				player.hitbox.height=8
			end		
		elseif player.position==down then
			player.hitbox.y+=8		
		end
		if player.punching>0 then
			if player.direction==right then
				player.hitbox.x-=1
			else
				player.hitbox.x+=1
			end
		end
		if player.strike_hit>0 then
			player.strike_hit-=1
		end
		if player.hurt>0 then
			player.hurt-=1
		end		
		if player.health<=0 then
			if test_mode==false then
				change_mode(mode_death)
			end
		end
		if (current_level%2==1 and player.x<=min_x) or
				(current_level%2==0 and player.x+15>=max_x) then
			change_mode(mode_complete)
		end
	elseif game_mode==mode_death then
		if player.direction==left then
			player.x+=gravity/2
		else
			player.x-=gravity/2
		end
		player.y+=gravity
		if player.y>camera_y+128 then
			change_mode(mode_start)
		end				
	elseif game_mode==mode_complete then
		if player.w_index==0 then
			player.sprite=2
		else
			player.sprite=6
		end
	end
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

function draw_player()
	rectfill(
		player.hitbox.x,
		player.hitbox.y,
		player.hitbox.x+player.hitbox.width,
		player.hitbox.y+player.hitbox.height,
		10
	)
	spr(player.sprite,player.x,player.y,2,2,player.flip_x)
end
-->8
-- ===================
-- enemies
-- ===================

function init_enemies()
	grab_guy=0
	knife_guy=1
	small_guy=2
	stick_guy=3
	enemy_group_counter=0
	enemy_counter=0
	enemy_group_counter=0
	boss_threshold=120
	enemies={}
	if current_level==1 then
		new_enemy(stick_guy,min_x)
	end
end

-- get an x for a new enemy
function random_enemy_x(offset)
	local left_x=camera_x-16-offset
	local right_x=camera_x+127+16+offset
	if player.x<min_x+boss_threshold then
		x=right_x
	elseif player.x>max_x-boss_threshold then
		x=left_x
	else
		local	r=flr(rnd(2))
		if r==0 then
			x=right_x
		else
			x=left_x
		end
	end
	return x
end

-- add a group of enemies
function more_enemies()
	if current_level==1 then
		for i=0,2 do
			local x=random_enemy_x(i*8)
			if i==2 and enemy_group_counter>2 then
				new_enemy(knife_guy,x)
				enemy_group_counter=0
			else
				new_enemy(grab_guy,x)
				enemy_group_counter+=1				
			end
		end
	end
end

-- return a new enemy
function new_enemy(kind,x)
	local enemy={
		kind=kind,
		x=x,
		y=baseline,
		body={
			x=x,
			y=baseline,
			width=8,
			height=16,
		},
		w_index=0,
		health=1,
		speed=1.5,
		grabbing=false,
		dead=false,
		facing=right,
		throwing=0,
		attack_height=up,
		cooldown=0,
		scored=false,
		shook=false,
		direction=direction,
		value=100,
		swinging=0,
		chain=0,
		tile_width=2,
		tile_height=2,
		boss=false,
		active=false,
		multiplier=1,
		attacking=0
	}
	if kind==knife_guy then
		enemy.health=2
		enemy.value=200
	elseif kind==small_guy then
		enemy.body.height=8
		enemy.body.width=8
		enemy.tile_width=1
		enemy.value=200
	elseif kind==stick_guy then
		enemy.boss=true
		enemy.health=10
		enemy.value=1000
	end
	if x<player.x then
		enemy.direction=right
	else
		enemy.direction=left
	end
	add(enemies,enemy)
end

-- -------
-- updates
-- -------

-- update all enemy movements
function update_enemies()
	if test_mode==false then
		if player.x>min_x+boss_threshold and
				player.x<max_x-boss_threshold then
			if ticks%100==0 then
				more_enemies()
			end		
		end
	end
	for enemy in all(enemies) do
		update_enemy(enemy)
		if enemy.y>camera_y+127 then
			del(enemies,enemy)
		end
	end
end

-- update one enemy's movement
function update_enemy(enemy)
	-- update walking index
	if ticks%3==0 then
		enemy.w_index+=1
		if enemy.w_index>1 then
			enemy.w_index=0
		end
	end
	-- face player (usually)
	if enemy.locked_direction then
		enemy.facing=enemy.locked_direction
	else
		if enemy.x<player.x then
			enemy.facing=right
		else
			enemy.facing=left
		end
	end
	-- should enemy run away?
	if enemy.boss==false then
		if (current_level%2==1 and player.x<min_x+boss_threshold) or
				(current_level%2==0 and player.x>max_x-boss_threshold)	then
			enemy.running=true
		end
	end
	-- set collision body
	enemy.body.x=enemy.x+4
	enemy.body.y=enemy.y
	if enemy.position==down then
		enemy.body.y+=4
		enemy.body.height=4
	end
	-- if no health then dead
	if enemy.health<=0 then
		enemy.dead=true
	end
	-- handling death/shookness
	if enemy.dead or enemy.shook then
		-- add score if appropriate
		if enemy.scored==false then
			new_score(enemy.x,enemy.y-8,enemy.value*enemy.multiplier)
			player.score+=enemy.value
			enemy.scored=true	
		end
		-- animated death movement
		if enemy.facing==right then
			enemy.x-=gravity/2
			enemy.y+=gravity
		else
			enemy.x+=gravity/2
			enemy.y+=gravity
		end
	-- move enemy if running
	elseif enemy.running then
		if enemy.x<player.x then
			enemy.direction=left
			enemy.facing=left
			enemy.x-=enemy.speed
		else
			enemy.direction=right
			enemy.facing=right
			enemy.x+=enemy.speed
		end
	-- otherwise normal movement
	else
		if enemy.kind==grab_guy then
			update_grab_guy(enemy)
		elseif enemy.kind==knife_guy then
			update_knife_guy(enemy)			
		elseif enemy.kind==small_guy then
			update_small_guy(enemy)	
		elseif enemy.kind==stick_guy then
			update_stick_guy(enemy)
		end
	end
	-- enemy ran into strike
	if collision(player.hitbox,enemy.body) and 
			(player.punching==9 or player.kicking==9) then
		new_effect(enemy_hit_effect,player.hitbox.x,player.hitbox.y)	
		player.strike_hit=3
		enemy.health-=1
		enemy.multiplier=1
		if enemy.boss==false and
				player.punching==9 then
			enemy.multiplier=2
		end
		sfx(-1)
		sfx(10)
	end
	-- sprite flip
	if enemy.facing==left then
		enemy.flip_x=true
	else
		enemy.flip_x=false
	end	
end

-- updates for grab_guy
function update_grab_guy(enemy)
	-- default sprite
	enemy.sprite=100
	-- grabbing sprite
	if enemy.grabbing then
		enemy.sprite=104
	-- dead sprite
	elseif enemy.dead or enemy.shook then
		enemy.sprite=106
	-- normal movement
	else
		enemy.sprite=100+enemy.w_index*2
		-- always move towards player
		if enemy.x<player.x then
			enemy.x+=enemy.speed
		elseif enemy.x>player.x then
			enemy.x-=enemy.speed
		end
		-- if touching then grab
		if collision(enemy.body,player.body) then
			player.grabbed=5
			player.jump_dir=0
			enemy.grabbing=true
		end
	end
end

-- updates for knife_guy
function update_knife_guy(enemy)
	-- sweet spot for throwing
	local target=0
	local window=8	
	enemy.sprite=128
	-- set target based on side
	if enemy.x<player.x then
		target=player.x-32
	else
		target=player.x+32
	end
	-- dead sprite
	if enemy.dead==true then
		enemy.sprite=140
	-- movement during throw
	elseif enemy.throwing>0 then
		if enemy.throwing>=5 then
			enemy.sprite=132
		else
			enemy.sprite=134
		end
		if enemy.attack_height==down then
			enemy.sprite+=4
		end
		if enemy.throwing==5 then
			local y=enemy.y-2
			if enemy.attack_height==down then
				y+=10
			end
			new_projectile(knife,enemy.x,y,2*enemy.direction,0)
		end
		if enemy.throwing==1 then
			enemy.attack_height*=-1
		end
		enemy.throwing-=1
	-- cooldown after throwing	
	elseif enemy.cooldown>0 then
		enemy.cooldown-=1
	-- normal movement
	else
		-- if less than sweet spot
		if enemy.x<target-8 then
			enemy.sprite+=enemy.w_index*2
			enemy.x+=enemy.speed
		-- if more than sweet spot
		elseif enemy.x>target+8 then
			enemy.sprite+=enemy.w_index*2
			enemy.x-=enemy.speed
		-- if sweet spot then throw
		else
			enemy.throwing=10
			enemy.cooldown=50
		end	
	end	
end

-- updates for small guy
function update_small_guy(enemy)
	-- sweet spot for jump attack
	local window=20
	local buffer=5
	-- body is smaller/lower
	enemy.body.x=enemy.x+2
	enemy.body.y=enemy.y+8
	-- default sprite
	enemy.sprite=108
	-- dead sprite
	if enemy.dead==true then
		enemy.sprite=108
	-- grabbing sprite
	elseif enemy.grabbing==true then
		enemy.sprite=109
	-- attacking
	elseif enemy.attacking>0 then
		enemy.x+=enemy.locked_direction*enemy.speed
		if enemy.attacking>10 then
			enemy.y-=1
		else
			enemy.y+=1
		end
		enemy.attacking-=1	
	-- normal movement
	else
		-- walking sprite
		enemy.sprite+=enemy.w_index
		-- always move towards player
		if enemy.x<player.x then
			-- attack if in window
			if enemy.x>=player.x-window-buffer and
					enemy.x<=player.x-window+buffer and
					player.position==down then
				enemy.attacking=window
				enemy.locked_direction=right
			else
				enemy.x+=enemy.speed
			end
		elseif enemy.x>player.x then
			if enemy.x<=player.x+15+window+buffer and
					enemy.x>=player.x+15+window-buffer and
					player.position==down then
				enemy.attacking=window
				enemy.locked_direction=left
			else
				enemy.x-=enemy.speed
			end
		end
		-- if touching then grab
		if collision(enemy.body,player.body) and
				enemy.locked_direction==nil then
			player.grabbed=5
			player.jump_dir=0
			enemy.grabbing=true
		end
	end
end

-- updates for stick_guy
function update_stick_guy(enemy)
	local target=player.x-8
	local window=2
	enemy.facing=enemy.direction
	enemy.sprite=160
	if enemy.active then
		if enemy.dead then
			enemy.sprite=172
		elseif enemy.swinging>0 then
			if enemy.swinging>=5 then
				enemy.sprite=164
			else
				enemy.sprite=166
			end
			if enemy.attack_height==low then
				enemy.sprite+=4
			end
			enemy.swinging-=1
		elseif enemy.cooldown>0 then
			enemy.cooldown-=1
			enemy.x-=enemy.speed
			enemy.sprite+=enemy.w_index*2
		else
			if enemy.x<target-window then
				enemy.sprite+=enemy.w_index*2
				enemy.x+=enemy.speed
			elseif enemy.x>target+window then
				enemy.sprite+=enemy.w_index*2
				enemy.x-=enemy.speed
			else
				if enemy.chain>2 then
					enemy.chain=0
					enemy.cooldown=15
				else
					enemy.attack_height=flr(rnd(2))
					enemy.chain+=1
					enemy.swinging=10
				end
			end
		end
	else
		if player.x<min_x+boss_threshold then
			enemy.active=true
		end
	end
end

-- -------
-- drawing
-- -------

-- draw all enemies to screen
function draw_enemies()
	for enemy in all(enemies) do
		draw_enemy(enemy)
	end
end

-- draw one enemy to screen
function draw_enemy(enemy)
	rectfill(
		enemy.body.x,
		enemy.body.y,
		enemy.body.x+enemy.body.width,
		enemy.body.y+enemy.body.height,
		10
	)
	spr(
			enemy.sprite,
			enemy.x,
			enemy.y,
			enemy.tile_width,
			enemy.tile_height,
			enemy.flip_x
	)
	if enemy.kind==stick_guy then
		if enemy.swinging>0 and enemy.swinging<5 and enemy.dead==false then
			if enemy.attack_height==high then
				line(enemy.x+15,enemy.y+2,enemy.x+19,enemy.y-2,0)
			else
				line(enemy.x+15,enemy.y+9,enemy.x+20,enemy.y+9,0)				
			end
		end
	end
end
-->8
--[[

todo:
	- small guy collision
	- knife collision effect
	- tally mode
	- snakes
	- dragons
	- mr. x
		
maybe:
		- boss for level 2?
		- parallax background?
		- bees?

]]

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
cccccc67777cccccccccccc777cccccccccccc77777cccccccccccc77c77ccccccccccc777cccccccccccc777c777ccccccccc777c777ccccccc9958899ccccc
ccccc776677cccccccccccc777ccccccccccc777c77ccccccccccc777c99cccccccccccc77ccccccccccc777ccc77cccccccc777ccc77cccccccc998798ccccc
cccc777cc777cccccccccc777ccccccccccc777cc777cccccccccc77cc000ccccccccccc777ccccccccc777ccc777ccccccc777ccc777ccccccc77977777cccc
ccc099cccc99cccccccccc99ccccccccccc099cccc99cccccccccc99ccccccccccccccccc99ccccccccc99cccc99cccccccc99cccc99cccccccc997cc799cccc
ccc0000ccc000ccccccccc000cccccccccc0000ccc000ccccccccc000ccccccccccccccc000ccccccccc000ccc000ccccccc000ccc000cccccc000cccc000ccc
ccccccccccccccccccccccccccccccccccccccccccccccccccccccc0000cccccccccccccc0000ccccccccccccccccccccccccc0000cccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccc00ccccccccccccc0999cccccccccccccc0999ccccccccccccccccccccccccc0999ccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccc0095cccccccccccc0919cccccccccccccc0919ccccccccccccccccccccccccc0919ccccccccc0ccccccccccccc
ccccccccccccccccccccccccc0000ccccccccc0999cccccccccccc9999ccccccccccccccc999ccccccccccccccccccccccccc9999cccccccc099ccccc99ccccc
ccccccc0000ccccccccccccc0999cccccccccc799ccccccccccccc799cccccc0cccccccc07700999ccccccc0000cccccccccc799ccccccccc0999cccc99ccccc
cccccc0999cccccccccccccc0919ccccccccc00770ccccccccccc70777cccc90ccccccc0770009c9cccccc0999cccccccccc70777cccccccc0099c0099cccccc
cccccc0919ccccccccccccccc999cccccccc0007709cccccccccc007970cc790ccccccc07700cccccccccc0919cccccccccc00797ccccccccc0777709ccccccc
ccccccc999cc9ccccccccccc07700999cccc90077799ccccccccc0099887777ccccccccc7777ccccccccccc999cccccccccc009988cccccccc000777cccccccc
cccccc00779c9cccccccccc0770009c9ccc990888cc99cccccccc099887877ccccccccc8888cccccccccc00790cccccccccc0998877ccccccc00077877cccccc
ccccc70009909cccccccccc07700ccccccc9cc7878c99ccccccccc9877779cccccccccc77777cccccccc0077770cccccccccc9877877cccccc007787777ccccc
ccccc70999099ccccccccccc7777ccccccc99c777cccccccccccccc7777cc9cccccccc777777cccccccc0077770ccccccccccc777777cccccc990877767ccccc
cccccc889987ccccccccccc8888cccccccccccc777cccccccccccccc777ccccccccccc777099cccccccc9958899ccccccccccc777099ccccccc99977077ccccc
cccccc7777787ccccccccc7777787cccccccccc777cccccccccccc7777ccccccccccc7777c000cccccccc9987987ccccccccc7777c000ccccccc99770977cccc
cccc97777c777ccccccc97777c777ccccccccc097cccccccccccc097cccccccccccc0977cccccccccccc7797777777cccccc0977cccccccccccccccc09777ccc
ccc09777ccc99cccccc09777ccc99cccccccccc09cccccccccccc09ccccccccccccc09cccccccccccccc997cccc77990cccc09cccccccccccccccccc0c7099cc
ccc00cccccc000ccccc00cccccc000cccccccccc00ccccccccccc0cccccccccccccc0cccccccccccccc000ccccccc000cccc0cccccccccccccccccccccc0000c
ccccccccbbbbbb3688888888888a888800000000cccccccc0000000000000000000000000000000000000000000000000000000000000000cccccaa3333c38cc
ccccccccbbbbb36baaaaa8aaaa8a8aaa00000000cccc33cc0000000000000000000000000000000000000000000000000000000000000000ccccc833883833cc
ccccccccbbbb36bbccccc8a88a8a8a8800000000ccc3333c0000000000000000000000000000000000000000000000000000000000000000cccc8c833333c7cc
ccccccccbbb36bbbccccc8a8888a888800000000ccc37ccc0000000000000000000000000000000000000000000000000000000000000000ccccc8c83ac7cccc
ccccccccbb36bbbbccccc8aaaa8a8aaa00000000cccc37cc0000000000000000000000000000000000000000000000000000000000000000ccccccc83aaccccc
ccccccccb36bbbbbccccc888888a888800000000cc88c37c0000000000000000000000000000000000000000000000000000000000000000cccccc8c83baaccc
cccccccc33333333cccccccccc8a8ccc00000000c833837c0000000000000000000000000000000000000000000000000000000000000000ccccccccc333bacc
cccccccc00000000cccccccccc8a8ccc0000000083c337cc0000000000000000000000000000000000000000000000000000000000000000ccccccccc8383bac
ffffffff7ccccccccccccccccc8a8ccccccaacccccccccccccccccccccffffccccffeecccccc7cccccccc8cc000000000000000000000000cccccccccc383bac
4444444467cccccccccccccccc8a8ccccca33acccccc33cccccccccccbffff8ccfeeffecc77cc77ccc888aac000000000000000000000000cccccc8cc833bbac
ffffffffc67cccccaaaaaaaaaaaaaaaaccbaabccccc3333cccccc8ccfbbff88feeffeeffc7fcff7cc8aaa777000000000000000000000000cccc8c8ccc3bbacc
ffffffff44ffffff8888888888888888ca3bb3acccc377ccbcc8cccbffbb88ffeeffeeff7ccccfcc8a77778c000000000000000000000000ccccc8a8c3bbaccc
44444444ccc555ccaaaaaaaaaaaaaaaacba33abccccc337cc8cccc8cfff88fffffeeffeeccfcccc7c8aaa777000000000000000000000000ccc88aa338bacccc
ffffffffcccc67ccccccccccccccccccc3baab3ccccccc37cb3cc3bcff88bbffffeeffeec7ffcf7ccc888aac000000000000000000000000ccccc8333baccccc
ffffffffccccc67ccccccccccccccccccc3bb3ccc8888c373c8338c3c88ffbbcceffeefcc77cc77cccccc8cc000000000000000000000000cccccccc3acccccc
ffffffffcccccc67ccccccccccccccccccc33ccc83c3337cc3b88b3cccffffcccceeffccccc7cccccccccccc000000000000000000000000cccccccccccccccc
4444444444444444cccccccc88888888ccccccc2222cccccccccccc2222cccccccccccc2222ccccccccccccccccccccccccccccccccccccccccc44cccccccccc
8888888888888888cccccccca8aaaaaacccccc2999cccccccccccc2999cccccccccccc2999ccccccccccccccccccccccccccccccccccccccccc4994cccc88ccc
8aaaaaa88aaaaaa8cc1ccccca8cccccccccccc2929cccccccccccc2929cccccccccccc2929cccccccc4ccccccccccccccccccccccccccccccc8339cccc3888cc
8a8888a88a8888a844177777a8cccccccccccc9999cccccccccccc9999cccccccccccc9999ccccccc499ccccc99cccccccccccccccccccccc883333cc338334c
8a8aaaa88aaaa8a84417777ca8cccccccccccc299ccccccccccccc299ccccccccccccc299cccccccc4999cccc99ccccccccc4444cccc4444c888333c83333394
8a888888888888a8cc1ccccc88ccccccccccc2f222cccccccccccff22fccccccccccccff22ccccccc4499cffffccccccccc4999cccc4999ccc3333cc89333994
8aaaaaaaaaaaaaa8cccccccccccccccccccccfff22ccccccccccfff222fcccccccccccfff2c99ccccc42222ffcccccccccc4939cccc4939cccc339cc8cc33c4c
8888888888888888cccccccccccccccccccccfff2299ccccccccff2222fccccccccccccffff99cccccff2222ccccccccccc9999cccc9999ccccc888ccccccccc
11111111112222118888888800000000ccccccf99299ccccccccff2222f99cccccccccc2fffcccccccff2222ffccccccccc499ccccc499ccc888cccccccccccc
11111111118e8811aaaaaaaa00000000ccccccf99fccccccccccf9922cc99ccccccccccfffccccccccff222ffffccccccc33883ccc33883ccc933cccc4c33cc8
1c1c1c1c118e8811cccccccc00000000cccccccfffccccccccccc99fffcccccccccccccfffccccccccffc2fff2fcccccc3388889cc33388ccc3333cc49933398
c1c1c1c1c18e8811cccccccc00000000cccccccfffccccccccccccfffffccccccccccccfffcccccccccf99ff2ffcccccc3998899ccc3998cc333888c49333338
1ccc1ccc17888871cccccccc00000000ccccccffffcccccccccccffffffcccccccccccffffcccccccccc99ff29ffcccccc993333cccc993cc333388cc433833c
cc1ccc1c11777711cccccccc00000000ccccc29ffcccccccccccfffccfffccccccccccfffccccccccccccccc29fffcccc333cc33cccc33cccc9338cccc8883cc
ccccccccc111111ccccccccc00000000ccccc29cccccccccccc299cccc99cccccccccc299ccccccccccccccc2cf299cc899cc99cccc99cccc4994cccccc88ccc
cccccccccccccccccccccccc00000000ccccc222ccccccccccc2222ccc222ccccccccc2222ccccccccccccccccc2222cc888c888ccc888cccc44cccccccccccc
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
cccccccc4444cccccccccccc4444cccc000009904444cccccccccccc4444ccccccc0ccccccccccccccccccccccccccccccccccc0cccccccc0000000000000000
ccccccc4999cccccccccccc4999cccccccccc994999cccccccccccc4999ccccccccc0ccccccccccccccccccccccccccccccccccc0ccccccc0000000000000000
ccccccc4919cccccccccccc4919c0ccccccccc64919cccccccccccc4919cccccccccc0ccccccccccccccccccccccccccccc4ccccc0cccccc0000000000000000
ccccccc9999cc0ccccccccc9999c0ccccccccc69999cccccccccccc9999cc99ccccccc0cc4444cccccccccccc4444ccccc499ccccc99cccc0000000000000000
ccccccc499ccc0ccccccccc499cc0ccccccccc6499ccccccccccccc499cc609cccccccc94999cccccccccccc4999cccccc4999cccc99cccc0000000000000000
cccccc66446cc0cccccccc46444c0ccccccccc44444ccccccccccc66446606ccccccccc949196ccccccccccc4919cccccc4499c6666c0ccc0000000000000000
ccccc6664446c0cccccccc66644c0ccccccccc46644cccccccccc66644466ccccccccccc99996ccccccccccc9999ccccccc4444466ccc0cc0000000000000000
ccccc6644446c0cccccccc6664499ccccccccc4666699cccccccc6644446cccccccccccc49966ccccccccccc499cccccccc664444ccccccc0000000000000000
ccccc664444699ccccccccc699499cccccccccc466699cccccccc664444ccccccccccc664446cccccccccc6644466699ccc66444466ccccc0000000000000000
ccccc69944cc99ccccccccc6996c0cccccccccc4444cccccccccc69944ccccccccccc666444cccccccccc66644460090ccc664446666cccc0000000000000000
cccccc99666cc0cccccccccc666ccccccccccccc666ccccccccccc996666ccccccccc6644466ccccccccc6644466ccccccc66c666646cccc0000000000000000
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
__label__
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888777777888eeeeee888eeeeee888eeeeee888eeeeee888eeeeee888eeeeee888888888888888888ff8ff8888228822888222822888888822888888228888
8888778887788ee88eee88ee888ee88ee888ee88ee8e8ee88ee888ee88ee8eeee88888888888888888ff888ff888222222888222822888882282888888222888
888777878778eeee8eee8eeeee8ee8eeeee8ee8eee8e8ee8eee8eeee8eee8eeee88888e88888888888ff888ff888282282888222888888228882888888288888
888777878778eeee8eee8eee888ee8eeee88ee8eee888ee8eee888ee8eee888ee8888eee8888888888ff888ff888222222888888222888228882888822288888
888777878778eeee8eee8eee8eeee8eeeee8ee8eeeee8ee8eeeee8ee8eee8e8ee88888e88888888888ff888ff888822228888228222888882282888222288888
888777888778eee888ee8eee888ee8eee888ee8eeeee8ee8eee888ee8eee888ee888888888888888888ff8ff8888828828888228222888888822888222888888
888777777778eeeeeeee8eeeeeeee8eeeeeeee8eeeeeeee8eeeeeeee8eeeeeeee888888888888888888888888888888888888888888888888888888888888888
1111111d111d11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1111111d111d11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1111111d111d11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
111111dd11dd11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111eee1eee11111666161116661616166616661111116616661666166616161666111116161666166617111ccc11111eee1e1e1eee1ee11111111111111111
111111e11e1111111616161116161616161116161111161111611616116116161611111116161161116111711c1c111111e11e1e1e111e1e1111111111111111
111111e11ee111111666161116617166166116611111166611611661116116611661111116661161116111171c1c111111e11eee1ee11e1e1111111111111111
111111e11e1111111611161116117716161116161111111611611616116116161611111116161161116111711c1c111111e11e1e1e111e1e1111111111111111
11111eee1e1111111611166616117771166616161171166111611616166616161666166616161666116117111ccc111111e11e1e1eee1e1e1111111111111111
11111111111111111111111111117777111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1111111111bb1bbb1bbb11711c117711111116661611166616161666166611111616166616661666116616161111161611111ccc111116661611166616161666
111111111b111b1b1b1b17111c11117111111616161116161616161116161111161611611161161616161616111116161111111c111116161611161616161611
111111111bbb1bbb1bb117111ccc1ccc111116661611166616661661166111111666116111611661161611611111116117771ccc111116661611166616661661
11111111111b1b111b1b17111c1c1c1c117116111611161611161611161611111616116111611616161616161111161611111c11117116111611161611161611
111111111bb11b111b1b11711ccc1ccc171116111666161616661666161611711616166611611666166116161171161611111ccc171116111666161616661666
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111eee1ee11ee11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111e111e1e1e1e1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111ee11e1e1e1e1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111e111e1e1e1e1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111eee1e1e1eee1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1eee1ee11ee111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1e111e1e1e1e11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1ee11e1e1e1e11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1e111e1e1e1e11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1eee1e1e1eee11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1eee1e1e1ee111ee1eee1eee11ee1ee1111116161666166116661666166611111666161116661616166616661171117111111111111111111111111111111111
1e111e1e1e1e1e1111e111e11e1e1e1e111116161616161616161161161111111616161116161616161116161711111711111111111111111111111111111111
1ee11e1e1e1e1e1111e111e11e1e1e1e111116161666161616661161166111111666161116661666166116611711111711111111111111111111111111111111
1e111e1e1e1e1e1111e111e11e1e1e1e111116161611161616161161161111111611161116161116161116161711111711111111111111111111111111111111
1e1111ee1e1e11ee11e11eee1ee11e1e111111661611166616161161166616661611166616161666166616161171117111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111eee1eee11111666166611661616116617171c1c111111111ccc11111eee1e1e1eee1ee11111111111111111111111111111111111111111111111111111
111111e11e1111111161116116111616161111171c1c177717771c1c111111e11e1e1e111e1e1111111111111111111111111111111111111111111111111111
111111e11ee111111161116116111661166611711ccc111111111c1c111111e11eee1ee11e1e1111111111111111111111111111111111111111111111111111
111111e11e111111116111611611161611161711111c177717771c1c111111e11e1e1e111e1e1111111111111111111111111111111111111111111111111111
11111eee1e111111116116661166161616611717111c111111111ccc111111e11e1e1eee1e1e1111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1111111116661611166616161666166611111616111116661661166116661616111111111cc11111111111111111111111111111111111111111111111111111
11111111161616111616161616111616111116161111116116161616161116161171177711c11111111111111111111111111111111111111111111111111111
11111111166616111666166616611661111116161111116116161616166111611777111111c11111111111111111111111111111111111111111111111111111
11111111161116111616111616111616111116661111116116161616161116161171177711c11111111111111111111111111111111111111111111111111111
1111111116111666161616661666161611711666166616661616166616661616111111111ccc1111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
111111111eee1eee11111666161116661616166616661111161611111666166116611666161617111cc111111eee1e1e1eee1ee1111111111111111111111111
1111111111e11e11111116161611161616161611161611111616111111611616161616111616117111c1111111e11e1e1e111e1e111111111111111111111111
1111111111e11ee1111116661611166616661661166111111616111111611616161616611161111711c1111111e11eee1ee11e1e111111111111111111111111
1111111111e11e11111116111611161611161611161611111666111111611616161616111616117111c1111111e11e1e1e111e1e111111111111111111111111
111111111eee1e1111111611166616161666166616161171166616661666161616661666161617111ccc111111e11e1e1eee1e1e111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1111111111111666161116661616166616661111161611111666166116611666161611111ccc1111111111111111111111111111111111111111111111111111
1111111111111616161116161616161116161111161611111161161616161611161617771c1c1111111111111111111111111111111111111111111111111111
1111111111111666161116661666166116611111161611111161161616161661116111111c1c1111111111111111111111111111111111111111111111111111
1111111111111611161116161116161116161111166611111161161616161611161617771c1c1111111111111111111111111111111111111111111111111111
1111111111111611166616161666166616161171166616661666161616661666161611111ccc1111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
111111111eee1ee11ee1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
111111111e111e1e1e1e111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
111111111ee11e1e1e1e111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
111111111e111e1e1e1e111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
111111111eee1e1e1eee111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111eee1ee11ee11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111e111e1e1e1e1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111ee11e1e1e1e1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111e111e1e1e1e1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111eee1e1e1eee1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111eee1eee111111661666166616661111166611661661166611111111166611661661166611111166166616661666166611111eee1e1e1eee1ee111111111
111111e11e111111161116161666161111111666161616161611177717771666161616161611111116111161161616161161111111e11e1e1e111e1e11111111
111111e11ee11111161116661616166111111616161616161661111111111616161616161661111116661161166616611161111111e11eee1ee11e1e11111111
111111e11e111111161616161616161111111616161616161611177717771616161616161611111111161161161616161161111111e11e1e1e111e1e11111111
11111eee1e111111166616161616166616661616166116661666111111111616166116661666166616611161161616161161111111e11e1e1eee1e1e11111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
111111111666161116661616166616661111161616661611161616661661116611111ccc1ccc1c1c1ccc11111111111111111111111111111111111111111111
1111111116161611161616161611161611111616161616111616116116161611177711c11c1c1c1c1c1111111111111111111111111111111111111111111111
1111111116661611166616661661166111111616166616111661116116161611111111c11cc11c1c1cc111111111111111111111111111111111111111111111
1111111116111611161611161611161611111666161616111616116116161616177711c11c1c1c1c1c1111111111111111111111111111111111111111111111
1111111116111666161616661666161611711666161616661616166616161666111111c11c1c11cc1ccc11111111111111111111111111111111111111111111
88888111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
88888111166616111666161616661666111116161111111116661611166616161666166611111166166616661666166117171666161116661616166616661111
88888111161616111616161616111616111116161171177716161611161616161611161611111611161616111611161611711616161116161616161116161111
88888111166616111666166616611661111111611777111116661611166616661661166111111666166616611661161617771666161116661666166116611111
88888111161116111616111616111616111116161171177716111611161611161611161611111116161116111611161611711611161116161116161116161111
88888111161116661616166616661616117116161111111116111666161616661666161611711661161116661666166617171611166616161666166616161171
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
82888222822882228888828882228222888282288222822882288888888888888888888888888888888882228288822282828882822282288222822288866688
82888828828282888888828882888282882888288282882888288888888888888888888888888888888888828288828282828828828288288282888288888888
82888828828282288888822282228222882888288282882888288888888888888888888888888888888888228222822282228828822288288222822288822288
82888828828282888888828288828882882888288282882888288888888888888888888888888888888888828282888288828828828288288882828888888888
82228222828282228888822282228882828882228222822282228888888888888888888888888888888882228222888288828288822282228882822288822288
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888

__gff__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001010101000000000000000000000000010101010000000000000000000000000101010100000000000000000000000001010100000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000020202020202020202020202020200000202020202020202020202020002000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
414141414141414140404040404040404a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a
424363724243637240404040404040404a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a
525352525253525240404040404040404a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a
404040404040404040404040404040404a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a
404040404040404040404040404040404a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a
404040404040404040404040404040404a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a
404040404040404040404040404040404a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a
505050505050505040404040404040404a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a
606160616160616040404040404040404a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a
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

