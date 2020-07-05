pico-8 cartridge // http://www.pico-8.com
version 27
__lua__
-- ===================
-- kung fu
-- andrew stephens
-- june 2020
-- version 0.1
-- ===================

test_mode=false
show_enemy_bodies=true
show_enemy_hitboxes=true
show_player_body=true
show_player_hitbox=true
skip_intro=true
logfile="kungfu"

palt(0,false)
palt(12,true)

-- constants
left=-1
right=1
up=-1
down=1
baseline=65
boss_health=15
enemy_strike_time=10
gravity=2
hurt_time=5
jump_max=18
level_size=80
mode_menu=0
mode_intro=1
mode_start=2
mode_play=3
mode_complete=4
mode_death=5
mode_gameover=6
mode_win=7
strike_duration=15
strike_contact=10
strike_hold=4
ticks=0
grab_guy=0
knife_guy=1
stick_guy=2
snake=3
enemy_group_counter=0
enemy_counter=0
enemy_group_counter=0
boss_threshold=120


-- globals
--first_run=true
min_x=0
max_x=level_size*8-1
current_level=1

-- ----------------------------
-- pico-8 main callbacks
-- ----------------------------

function _init()	
	-- enable full keys if testing
	if test_mode then
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
		draw_test_osd()
	end
end

-- ----------------------------
-- helper routines
-- ----------------------------

-- print something centred
function center_print(text,xc,y,c)
	local w=#text*4
	local x=xc-w/2-4
	rectfill(x-1,y-1,x+w-1,y+5,0)
	print(text,x,y,c)
end

-- change game mode
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

-- is there a collision?
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

-- print to log
function debug(message)
	printh(message,"kungfu")
end

-- draw the current level
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
	--spr(192,min_x+boss_threshold,baseline)
	--spr(192,max_x-boss_threshold,baseline)
end

-- draw the osd
function draw_osd()
 function get_boss_health()
  for enemy in all(enemies) do
   if enemy.boss then
    return enemy.health/boss_health
   end
  end
  return 0
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
	health_bar(x+25,y+8,get_boss_health(),8)	
	draw_osd_level(x+50,y)
	print("life:1",x+55,y+8,7)
	print("000000",x+91,y,7)
	print("time:"..flr(level_timer),x+85,y+8,7)
	rectfill(camera_x,camera_y+105,camera_x+127,camera_y+127,0)
end

-- draw test info osd
function draw_test_osd()
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

-- is strike a climax
function is_climax(strike)
	return strike>strike_contact-strike_hold and
		strike<strike_contact+strike_hold
end

-- is object offscreen?
function is_offscreen(r)
	local cx=camera_x
	return 
			(r.direction==left and r.x<cx-r.tile_width*8) or
			(r.direction==right and r.x>cx+127+r.tile_width*8) or
			r.y>127
end

-- return new entity
function new_entity()
	return {
		x=0,
		y=baseline,
		w_index=0,
		direction=right,
		position=up,
		speed=1,
		health=100,
		height=16,
		hurt=0,
		tile_height=2,
		tile_width=2,
	}
end

-- process all collisions
function process_collisions()
	-- body collisions
	for enemy in all(enemies) do
		if collision(enemy.body,player.body) then
			debug('collision')
			if enemy.kind==grab_guy then
				if enemy.grabbing==false then
					player.grabbed=3
					player.jump_dir=0
					enemy.grabbing=true
				end
			elseif enemy.kind==snake then
				player.health-=enemy.power
				player.hurt=hurt_time
			end
		end
	end
	-- enemy strikes
	for enemy in all(enemies) do
		if collision(enemy.hitbox,player.body) then
			if enemy.kind==stick_guy then
				if	enemy.swinging==1 then
					player.health-=enemy.power
					player.hurt=hurt_time
					new_effect(player_hit_effect,enemy.hitbox.x,enemy.hitbox.y)						
				end
			end
		end
	end
	-- player strikes
	for enemy in all(enemies) do
		if collision(player.hitbox,enemy.body) then
			if is_climax(player.punching) or
					is_climax(player.kicking) then	
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
		end
	end
end

-- input for test mode
function test_input()
	local key=stat(31)
	local num=tonum(key)
	if game_mode==mode_play then
		if num then
			new_enemy(num-1,random_enemy_x(0))
			if enemies[#enemies].boss then
				enemies[#enemies].active=true
			end
		end
	end
end

-- update object's body
function update_body(o)
	o.body={}
	o.body.width=8
	o.body.height=8
	o.body.x=o.x
	o.body.y=o.y
	if o.tile_width==2 then
		o.body.x=o.x+4
	end
	if o.tile_height==2 then
		o.body.height=16
	end
	if o.position==down then
		o.body.y=o.y+8
	end
end

-- update camera
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

-- update object's hitbox
function update_hitbox(o)
	o.hitbox={}
	o.hitbox.width=4
	o.hitbox.height=4
	o.hitbox.x=o.x
	o.hitbox.y=o.y
	if o.jumping==nil then
		o.jumping=0
	end
	if o.kicking==nil then
		o.kicking=0
	end
	if o.direction==left then
		o.hitbox.x=o.x-2
	else
		o.hitbox.x=o.x+14
	end
	if (o.jumping>0 and o.kicking>0) or
			o.position==down then
		o.hitbox.y=o.y+8
	end
end

-- ----------------------------
-- effects
-- ----------------------------

function init_effects()
	effects={}
	enemy_hit_effect=0
	player_hit_effect=1
	urn_break_effect=2
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
		if effect.kind==enemy_hit_effect then
			print("✽",effect.x,effect.y,7)		
		elseif effect.kind==player_hit_effect then
			print("✽",effect.x,effect.y,8)			
		end
	end
end

-- ----------------------------
-- enemies
-- ----------------------------

function init_enemies()
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
	elseif current_level==2 then
		new_enemy(snake,player.x)
	end
end

-- create new enemy
function new_enemy(kind,x)
	local enemy=new_entity()
	enemy.attack_height=up
	enemy.active=false
	enemy.boss=false
	enemy.dead=false
	enemy.multiplier=1
	enemy.health=1
	enemy.kind=kind
	enemy.power=1
	enemy.scored=false
	enemy.speed=1.25
	enemy.value=100
	enemy.x=x
	enemy.y=baseline
	if kind==grab_guy then
		enemy.grabbing=false
		enemy.shook=false
	elseif kind==knife_guy then
		enemy.cooldown=0
		enemy.health=2
		enemy.throwing=0
		enemy.value=200
		enemy.walking=false
	elseif kind==stick_guy then
		enemy.boss=true
		enemy.chain=0
		enemy.cooldown=0
		enemy.health=boss_health
		enemy.power=20
		enemy.swinging=0
		enemy.value=1000
	elseif kind==snake then
		enemy.breaking=0
		enemy.value=200
		enemy.speed=2
		enemy.tile_height=1
		enemy.tile_width=1
		enemy.y=camera_y-8
	end
	update_body(enemy)
	update_hitbox(enemy)
	if x<player.x then
		enemy.direction=right
	else
		enemy.direction=left
	end
	add(enemies,enemy)
end

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
	-- update body
	update_body(enemy)
	-- update hitbox
	update_hitbox(enemy)
	-- face player (usually)
	if enemy.locked_direction then
		enemy.direction=enemy.locked_direction
	else
		if enemy.x<player.x then
			enemy.direction=right
		else
			enemy.direction=left
		end
	end
	-- should enemy run away?
	if enemy.boss==false then
		if (current_level%2==1 and player.x<min_x+boss_threshold) or
				(current_level%2==0 and player.x>max_x-boss_threshold)	then
			enemy.running=true
		end
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
		if enemy.direction==right then
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
			enemy.x-=enemy.speed
		else
			enemy.direction=right
			enemy.x+=enemy.speed
		end
	-- otherwise normal movement
	else
		if enemy.kind==grab_guy then
			update_grab_guy(enemy)
		elseif enemy.kind==knife_guy then
			update_knife_guy(enemy)			
		elseif enemy.kind==stick_guy then
			update_stick_guy(enemy)
		elseif enemy.kind==snake then
			update_snake(enemy)
		end
	end
end

-- updates for grab_guy
function update_grab_guy(enemy)
	if enemy.grabbing==false then
		-- always move towards player
		if enemy.x<player.x then
			enemy.x+=enemy.speed
		elseif enemy.x>player.x then
			enemy.x-=enemy.speed
		end
	end
end

-- updates for knife_guy
function update_knife_guy(enemy)
	-- sweet spot for throwing
	local target=0
	local window=8	
	enemy.walking=false
	-- set target based on side
	if enemy.x<player.x then
		target=player.x-32
	else
		target=player.x+32
	end
	-- if throwing
	if enemy.throwing>0 then
		-- time of release
		if enemy.throwing==5 then
			local y=enemy.y-2
			if enemy.attack_height==down then
				y+=10
			end
			new_projectile(knife,enemy.x,y,2*enemy.direction,0)
		end
		-- change attack height
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
			enemy.direction=right
			enemy.walking=true
			enemy.x+=enemy.speed
		-- if more than sweet spot
		elseif enemy.x>target+8 then
			enemy.direction=left
			enemy.walking=true
			enemy.x-=enemy.speed
		-- if sweet spot then throw
		else
			enemy.throwing=10
			enemy.cooldown=50
		end	
	end	
end

-- updates for stick_guy
function update_stick_guy(enemy)
	local target=player.x-8
	local window=2
	update_body(enemy)
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
			if enemy.position==down then
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
					local n=flr(rnd(2))
					if n==0 then 
						n=-1
					end
					enemy.position=n
					enemy.chain+=1
					enemy.swinging=enemy_strike_time
					update_hitbox(enemy)
				end
			end
		end
	else
		if player.x<min_x+boss_threshold then
			enemy.active=true
		end
	end
end

-- update snake
function update_snake(enemy)
	if enemy.breaking>0 then
		enemy.breaking-=1
		if enemy.breaking<1 then
			enemy.active=true
		end
	elseif enemy.active==false then
		enemy.y+=enemy.speed
		if enemy.y>baseline+8 then
			enemy.y=baseline+8
			enemy.breaking=5
		end
	elseif enemy.locked_direction==nil then	
		if enemy.x<player.x then
			enemy.locked_direction=right
		else
			enemy.locked_direction=left
		end
	else
		enemy.x+=enemy.speed*enemy.locked_direction
	end
	update_body(enemy)
	debug(player.y)
end

-- draw all enemies to screen
function draw_enemies()
	for enemy in all(enemies) do
		draw_enemy(enemy)
	end
end

-- draw one enemy to screen
function draw_enemy(enemy)

	-- show bodies (test mode)
	if test_mode and show_enemy_bodies then
		local x=enemy.body.x-20
		local y=enemy.body.y-20
		cursor(x,y)
		print("enemy.x:"..enemy.x)
		print("enemy.body.x:"..enemy.body.x)

		rectfill(
			enemy.body.x,
			enemy.body.y,
			enemy.body.x+enemy.body.width-1,
			enemy.body.y+enemy.body.height-1,
			10
		)
	end

	-- show hitboxes (test mode)
	if test_mode and show_hitboxes then
		if enemy.hitbox then
			rectfill(
				enemy.hitbox.x,
				enemy.hitbox.y,
				enemy.hitbox.x+enemy.hitbox.width-1,
				enemy.hitbox.y+enemy.hitbox.height-1,
				10
			)
		end
	end
	
	-- grab guy sprites
	if enemy.kind==grab_guy then
		enemy.sprite=100+enemy.w_index*2
		if enemy.grabbing then
			enemy.sprite=104
		elseif enemy.dead or enemy.shook then
			enemy.sprite=106
		end

	--knife guy sprites
	elseif enemy.kind==knife_guy then
		enemy.sprite=128
		if enemy.dead==true then
			enemy.sprite=140
		elseif enemy.throwing>0 then
			if enemy.throwing>=5 then
				enemy.sprite=132
			else
				enemy.sprite=134
			end
			if enemy.attack_height==down then
				enemy.sprite+=4
			end
		elseif enemy.walking then
			enemy.sprite+=enemy.w_index*2
		end	

	elseif enemy.kind==snake then
		enemy.sprite=110
		if enemy.breaking>0 then
			enemy.sprite=111
		elseif enemy.active then
			enemy.sprite=126+enemy.w_index
		end
	end

	-- sprite flip
	if enemy.direction==left then
		enemy.flip_x=true
	else
		enemy.flip_x=false
	end	

	-- draw the sprite
	spr(
			enemy.sprite,
			enemy.x,
			enemy.y,
			enemy.tile_width,
			enemy.tile_height,
			enemy.flip_x
	)

	-- some guys need more stuff
	if enemy.kind==stick_guy then
		if enemy.swinging>0 and enemy.swinging<5 and enemy.dead==false then
			if enemy.position==up then
				line(enemy.x+15,enemy.y+2,enemy.x+19,enemy.y-2,0)
			else
				line(enemy.x+15,enemy.y+9,enemy.x+20,enemy.y+9,0)				
			end
		end
	end

end

-- ----------------------------
-- player
-- ----------------------------

function init_player()
	player=new_entity()
	player.grabbed=0
	player.jumping=0
	player.kicking=0
	player.punching=0
	player.score=0
	update_body(player)
	update_hitbox(player)
	if current_level%2==1 then
		player.x=max_x-16
		player.direction=left
	end
end

-- get game input
function player_input()
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
				player.jumping=jump_max
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
			player.kicking=strike_duration
			sfx(9)
		end
		player.btn4_down=true
	else
		player.btn4_down=false
	end
	if btn(5) and player.grabbed<1 then
		if player.btn5_down==false then
			player.punching=strike_duration
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
		if player.w_index>1 then
			player.w_index=0
		end
	end	
	
	if game_mode==mode_start then
		player.walking=true
		player.x+=player.speed*player.direction
	
	-- play mode
	elseif game_mode==mode_play then
		player_input()
		-- shake off grabbers
		if player.last_direction~=player.direction then
			player.grabbed-=1
			if player.grabbed<0 then
				player.grabbed=0
			end		
		end
		-- lose health if grabbed
		if player.grabbed>0 then
				player.health-=0.5
		else
			-- else drop all grabbers
			for enemy in all(enemies) do
				if enemy.grabbing==true then
					enemy.shook=true
				end
			end
		end
		-- *** bug:
		--		- sometimes stuck in grab
		-- apply gravity/momentum
		if player.jumping>0 then
			player.x+=player.jump_dir*player.speed
		end
		if player.jumping>jump_max/2 then
			player.y-=gravity
		else
			player.y+=gravity
			if player.y>baseline then
				player.y=baseline
			end
		end
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
		update_body(player)
		-- update the hitbox
		update_hitbox(player)
		-- if player is hurt
		if player.hurt>0 then
			player.hurt-=1
		end
		-- if no health left then die
		if player.health<=0 then
			if test_mode==false then
				change_mode(mode_death)
			end
		end
		-- if we're at end of level
		if (current_level%2==1 and player.x<=min_x) or
				(current_level%2==0 and player.x+15>=max_x) then
			change_mode(mode_complete)
		end
		player.last_direction=player.direction
		
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
		-- *** move this
		if player.w_index==0 then
			player.sprite=2
		else
			player.sprite=6
		end
	end
	
end

function draw_player()

	if test_mode and show_player_body then
		rectfill(
			player.body.x,
			player.body.y,
			player.body.x+player.body.width-1,
			player.body.y+player.body.height-1,
			10
		)
	end

	-- default sprite
	player.sprite=0

	-- dead sprite
	if game_mode==mode_death then
		player.sprite=46

	-- player hurt sprite
	elseif player.hurt>0 then
		player.sprite=36

	-- jumping
	elseif player.jumping>0 then
		-- default jump sprite
		player.sprite=2
		-- if kicking
		if player.kicking>0 then
			player.sprite=44
			-- if climax of kick
			if is_climax(player.kicking) then
				player.sprite=38
			end
		-- if punching
		elseif player.punching>0 then
			player.sprite=44
			-- if climax of punch
			if is_climax(player.punching) then
				player.sprite=40
			end
		end
						
	-- ducking
	elseif player.position==down then
		-- default ducking sprite
		player.sprite=14
		-- if kicking
		if player.kicking>0 then
			player.sprite=32
			-- if climax of kick
			if is_climax(player.kicking) then
   	player.sprite=42
   end
  -- if punching
  elseif player.punching>0 then
  	player.sprite=32
  	-- if climax of punch
  	if is_climax(player.punching) then
  		player.sprite=34
  	end
  end
  
	-- walking
	elseif player.walking==true then
		player.sprite=player.w_index*2
		
	-- in normal state
	else
		-- if kicking
		if player.kicking>0 then
			player.sprite=10
			-- if climax of kick
			if is_climax(player.kicking) then
				player.sprite=8
			end
		-- if punching
		elseif player.punching>0 then
			player.sprite=10
			-- if climax of punch
			if is_climax(player.punching) then
				player.sprite=12
			end
		end
	
	end
				
	-- flip if looking left
	player.flip_x=false
	if player.direction==left then
		player.flip_x=true
	end
	
	-- debug - show bodies/hitbox
	if test_mode and show_player_hitbox then
		rectfill(
			player.hitbox.x,
			player.hitbox.y,
			player.hitbox.x+player.hitbox.width-1,
			player.hitbox.y+player.hitbox.height-1,
			10
		)
	end
	
	-- draw the sprite
	spr(
		player.sprite,
		player.x,
		player.y,
		player.tile_width,
		player.tile_height,
		player.flip_x
	)

end

-- ----------------------------
-- projectiles
-- ----------------------------

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
			player.hurt=hurt_time
			player.health-=10
			del(projectiles,projectile)
		elseif	is_offscreen(projectile) then
			del(projectiles,projectile)
		end
	end	
end

-- ------
-- scores
-- ------

function init_scores()
	scores={}
end

function draw_scores()
 for score in all(scores) do
 	print(score.n,score.x+1,score.y+1,0)
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

-- ----------------------------
-- game modes
-- ----------------------------

-- complete level program

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

-- death program

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

-- intro program

function mode_intro_init()
	init_player()
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

-- menu program

function mode_menu_update()
	if btn(4) and btn(5) then
		if skip_intro then
			change_mode(mode_start)
		else
			change_mode(mode_intro)
		end
	end
end

function mode_menu_draw()
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
	-- save space on spritesheet
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

-- play (main) program

function mode_play_init()
	music(0)
end

function mode_play_update()
	if test_mode then
		test_input()
	end
	update_effects()
	update_enemies()
	update_player()
	update_projectiles()
	process_collisions()
	update_scores()
	update_camera()
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

-- start program

function mode_start_init()
	level_timer=2000
	init_player()
	init_effects()
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

-- tally program

function mode_tally_init()
	current_level+=1
	change_mode(mode_start)
end

function mode_tally_update()
end

function mode_tally_draw()
end
-->8
--[[

todo:
	- knife collision effect
	- tally mode
	- snakes
	- dragons
	- mr. x
	- sometimes player is stuck
			in grab
	- stair animation
		
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
ccccccc0000ccccccccccccc0999cccccccccc799ccccccccccccc799cccccc0cccccccc07700999cccccc0000ccccccccccc799ccccccccc0999cccc99ccccc
cccccc0999cccccccccccccc0919ccccccccc00770ccccccccccc70777cccc90ccccccc0770009c9ccccc0999ccccccccccc70777cccccccc0099c0099cccccc
cccccc0919ccccccccccccccc999cccccccc0007709cccccccccc007970cc790ccccccc07700ccccccccc0919ccccccccccc00797ccccccccc0777709ccccccc
ccccccc999cc9ccccccccccc07700999cccc90077799ccccccccc0099887777ccccccccc7777cccccccccc999ccccccccccc009988cccccccc000777cccccccc
cccccc00779c9cccccccccc0770009c9ccc990888cc99cccccccc099887877ccccccccc8888cccccccccc00790cccccccccc0998877ccccccc00077877cccccc
ccccc70009909cccccccccc07700ccccccc9cc7878c99ccccccccc9877779cccccccccc77777cccccccc0077770cccccccccc9877877cccccc007787777ccccc
ccccc70999099ccccccccccc7777ccccccc99c777cccccccccccccc7777cc9cccccccc777777cccccccc0077770ccccccccccc777777cccccc990877767ccccc
cccccc889987ccccccccccc8888cccccccccccc777cccccccccccccc777ccccccccccc777099cccccccc9958899ccccccccccc777099ccccccc99977077ccccc
cccccc7777787ccccccccc7777787cccccccccc777cccccccccccc7777ccccccccccc7777c000cccccccc9987987ccccccccc7777c000ccccccc99770977cccc
cccc97777c777ccccccc97777c777ccccccccc097cccccccccccc097cccccccccccc0977cccccccccccc7797777777cccccc0977cccccccccccccccc09777ccc
ccc09777ccc99cccccc09777ccc99cccccccccc09cccccccccccc09ccccccccccccc09cccccccccccccc997cccc77990cccc09cccccccccccccccccc0c7099cc
ccc00cccccc000ccccc00cccccc000cccccccccc00ccccccccccc0cccccccccccccc0cccccccccccccc000ccccccc000cccc0cccccccccccccccccccccc0000c
ccccccccbbbbbb3688888888888888880000000000000000000000000000000000000000000000000000000000000000cccccaa3333c38cccccccaa3333c38cc
ccccccccbbbbb36baaa8aaaa8a8aaaaa0000000000000000000000000000000000000000000000000000000000000000ccccc833883833ccccccc833883833cc
ccccccccbbbb36bbccc8a88a8a8a88a80000000000000000000000000000000000000000000000000000000000000000cccc8c833333c7cccccc8c833333c7cc
ccccccccbbb36bbbccc8a8888a8888a80000000000000000000000000000000000000000000000000000000000000000ccccc8c83ac7ccccccccc8c83ac7cccc
ccccccccbb36bbbbccc8aaaa8a8aaaa80000000000000000000000000000000000000000000000000000000000000000ccccccc83aacccccccccccc83aaccccc
ccccccccb36bbbbbccc888888a8888880000000000000000000000000000000000000000000000000000000000000000cccccc8c83baaccccccccc8c83baaccc
cccccccc33333333cccccccc8a8ccccc0000000000000000000000000000000000000000000000000000000000000000ccccccccc333baccccccccccc333bacc
cccccccc00000000cccccccc8a8ccccc0000000000000000000000000000000000000000000000000000000000000000ccccccccc8383bacccccccccc8383bac
ffffffff7ccccccccccccccc8a8ccccc0000000000000000000000000000000000000000000000000000000000000000cccccccccc383baccccccccccc383bac
4444444467cccccccccccccc8a8ccccc0000000000000000000000000000000000000000000000000000000000000000cccccc8cc833bbaccccccc8cc833bbac
ffffffffc67cccccaaaaaaaaaaaaaaaa0000000000000000000000000000000000000000000000000000000000000000cccc8c8ccc3bbacccccc8c8ccc3bbacc
ffffffff44ffffff88888888888888880000000000000000000000000000000000000000000000000000000000000000ccccc8a8c3bbacccccccc8a8c3bbaccc
44444444ccc555ccaaaaaaaaaaaaaaaa0000000000000000000000000000000000000000000000000000000000000000ccc88aa338baccccccc88aa338bacccc
ffffffffcccc67cccccccccccccccccc0000000000000000000000000000000000000000000000000000000000000000ccccc8333bacccccccccc8333baccccc
ffffffffccccc67ccccccccccccccccc0000000000000000000000000000000000000000000000000000000000000000cccccccc3acccccccccccccc3acccccc
ffffffffcccccc67cccccccccccccccc0000000000000000000000000000000000000000000000000000000000000000cccccccccccccccccccccccccccccccc
4444444444444444cccccccc88888888ccccccc2222cccccccccccc2222cccccccccccc2222cccccccccccccccccccccccffffccccccc8cccccaaccccccccccc
8888888888888888cccccccca8aaaaaacccccc2999cccccccccccc2999cccccccccccc2999cccccccccccccccccccccccbffff8ccc888aaccca33acccccccccc
8aaaaaa88aaaaaa8cc1ccccca8cccccccccccc2929cccccccccccc2929cccccccccccc2929cccccccc4cccccccccccccfbbff88fc8aaa777ccbaabccccccc8cc
8a8888a88a8888a844177777a8cccccccccccc9999cccccccccccc9999cccccccccccc9999ccccccc499ccccc99cccccffbb88ff8a77778cca3bb3acbcc8cccb
8a8aaaa88aaaa8a84417777ca8cccccccccccc299ccccccccccccc299ccccccccccccc299cccccccc4999cccc99cccccfff88fffc8aaa777cba33abcc8cccc8c
8a888888888888a8cc1ccccc88ccccccccccc2f222cccccccccccff22fccccccccccccff22ccccccc4499cffffccccccff88bbffcc888aacc3baab3ccb3cc3bc
8aaaaaaaaaaaaaa8cccccccccccccccccccccfff22ccccccccccfff222fcccccccccccfff2c99ccccc42222ffcccccccc88ffbbcccccc8cccc3bb3cc3c8338c3
8888888888888888cccccccccccccccccccccfff2299ccccccccff2222fccccccccccccffff99cccccff2222ccccccccccffffccccccccccccc33cccc3b88b3c
111111111122221188888888ccffccccccccccf99299ccccccccff2222f99cccccccccc2fffcccccccff2222ffccccccccffeecccccc7ccccccccccccccccccc
11111111118e8811aaaaaaaaccffccccccccccf99fccccccccccf9922cc99ccccccccccfffccccccccff222ffffccccccfeeffecc77cc77ccccc33cccccc33cc
1c1c1c1c118e8811ccccccccf4ff4fffcccccccfffccccccccccc99fffcccccccccccccfffccccccccffc2fff2fccccceeffeeffc7fcff7cccc3333cccc3333c
c1c1c1c1c18e8811ccccccccf4ff4fffcccccccfffccccccccccccfffffccccccccccccfffcccccccccf99ff2ffccccceeffeeff7ccccfccccc37cccccc377cc
1ccc1ccc17888871ccccccccccffccccccccccffffcccccccccccffffffcccccccccccffffcccccccccc99ff29ffccccffeeffeeccfcccc7cccc37cccccc337c
cc1ccc1c11777711ccccccccccffccccccccc29ffcccccccccccfffccfffccccccccccfffccccccccccccccc29fffcccffeeffeec7ffcf7ccc88c37ccccccc37
ccccccccc111111cccccccccccffccccccccc29cccccccccccc299cccc99cccccccccc299ccccccccccccccc2cf299ccceffeefcc77cc77cc833837cc8888c37
ccccccccccccccccccccccccccffccccccccc222ccccccccccc2222ccc222ccccccccc2222ccccccccccccccccc2222ccceeffccccc7cccc83c337cc83c3337c
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
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
8aaaaaa88aaaaaa88aaaaaa88aaaaaa88aaaaaa88aaaaaa88aaaaaa88aaaaaa88aaaaaa88aaaaaa88aaaaaa88aaaaaa88aaaaaa88aaaaaa88aaaaaa88aaaaaa8
8a8888a88a8888a88a8888a88a8888a88a8888a88a8888a88a8888a88a8888a88a8888a88a8888a88a8888a88a8888a88a8888a88a8888a88a8888a88a8888a8
8a8aaaa88aaaa8a88a8aaaa88aaaa8a88a8aaaa88aaaa8a88a8aaaa88aaaa8a88a8aaaa88aaaa8a88a8aaaa88aaaa8a88a8aaaa88aaaa8a88a8aaaa88aaaa8a8
8a888888888888a88a888888888888a88a888888888888a88a888888888888a88a888888888888a88a888888888888a88a888888888888a88a888888888888a8
8aaaaaaaaaaaaaa88aaaaaaaaaaaaaa88aaaaaaaaaaaaaa88aaaaaaaaaaaaaa88aaaaaaaaaaaaaa88aaaaaaaaaaaaaa88aaaaaaaaaaaaaa88aaaaaaaaaaaaaa8
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000990099009900990099999000099999000000000999999009900990000000000000000000000000000000000000
00000000000000000000000000000000000008990899089908990899999900999999000000008999999089908990000000000000000000000000000000000000
00000000000000000000000000000000000008999999089908990899889908998880000000008998880089908990000000000000000000000000000000000000
00000000000000000000000000000000000008999990089908990899089908990000000000008999999089908990000000000000000000000000000000000000
00000000000000000000000000000000000008999990089908990899089908990099000000008999999089908990000000000000000000000000000000000000
00000000000000000000000000000000000008998899089999990899089908999999000000008998880089999990000000000000000000000000000000000000
00000000000000000000000000000000000008990899089999900899089908999999000000008990000089999900000000000000000000000000000000000000
00000000000000000000000000000000000008800880088888000880088008888880000000008880000088888000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
8aaaaaa88aaaaaa88aaaaaa88aaaaaa88aaaaaa88aaaaaa88aaaaaa88aaaaaa88aaaaaa88aaaaaa88aaaaaa88aaaaaa88aaaaaa88aaaaaa88aaaaaa88aaaaaa8
8a8888a88a8888a88a8888a88a8888a88a8888a88a8888a88a8888a88a8888a88a8888a88a8888a88a8888a88a8888a88a8888a88a8888a88a8888a88a8888a8
8a8aaaa88aaaa8a88a8aaaa88aaaa8a88a8aaaa88aaaa8a88a8aaaa88aaaa8a88a8aaaa88aaaa8a88a8aaaa88aaaa8a88a8aaaa88aaaa8a88a8aaaa88aaaa8a8
8a888888888888a88a888888888888a88a888888888888a88a888888888888a88a888888888888a88a888888888888a88a888888888888a88a888888888888a8
8aaaaaaaaaaaaaa88aaaaaaaaaaaaaa88aaaaaaaaaaaaaa88aaaaaaaaaaaaaa88aaaaaaaaaaaaaa88aaaaaaaaaaaaaa88aaaaaaaaaaaaaa88aaaaaaaaaaaaaa8
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000aa3333038000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008303333aa00000000000
00000000008338838330000000000000000000000000000000000000000000000000000000000000000000000000000000000000000033838833800000000000
00000000080833333070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000070333338080000000000
00000000008083a0700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000070a380800000000000
00000000000083aa00000000777077707770077007700000077777000000077777000000777007700000077077707770777077700000000aa380000000000000
000000000008083baa0000007070707070007000700000007700077007007707077000000700707000007000070070707070070000000aab3808000000000000
00000000000000333ba00000777077007700777077700000770707707770777077700000070070700000777007007770770007000000ab333000000000000000
000000000000008383ba000070007070700000700070000077000770070077070770000007007070000000700700707070700700000ab3838000000000000000
000000000000000383ba000070007070777077007700000007777700000007777700000007007700000077000700707070700700000ab3830000000000000000
00000000000800833bba000000000000000000000000000000000000000000000000000000000000000000000000000000000000000abb338008000000000000
0000000008080003bba00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000abb30008080000000000
00000000008a803bba0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000abb308a800000000000
0000000088aa338ba000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ab833aa88000000000
00000000008333ba00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ab333800000000000
00000000000003a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a300000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

__gff__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001010101000000000000000000000000010101010000000000000000000000000101010100000000000000000000000001010100000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000020202020202020202020202020200000202020202020202020202020002000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
4141414141414141444540404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040
4243727242437272545540404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040
5253525252535252444540404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040
4040404040404040545540404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040
4040404040404040444540404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040
4040404040404040545540404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040
4040404040404040444540404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040
5050505050505050545540404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040
6061606160616061444540404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040
7170707041414141545540404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040
4040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040
4040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040
4040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040
4040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040
4040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040
4040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040
4040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040
4040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040
4040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040
4040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040
4040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040
4040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040
4040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040
4040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040
4040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040
4040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040
4040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040
4040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040
4040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040
4040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040
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

