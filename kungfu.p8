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
show_enemy_hitboxes=false
show_player_body=false
show_player_hitbox=true
skip_cutscene=true
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
strike_duration=15
strike_contact=10
strike_hold=4
ticks=0
fire_time=30
cutscene_timer=0
cutscene_flash=false

enemy_group_counter=0
enemy_counter=0
enemy_group_counter=0
boss_threshold=64

-- globals
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
	change_mode("menu")
	printh("kungfu.p8 log",logfile,true)
end

function _update()
	ticks=ticks+1
	if game_mode=="menu" then
		mode_menu_update()
	elseif game_mode=="intro" then
		mode_intro_update()
	elseif game_mode=="start" then
		mode_start_update()
	elseif game_mode=="play" then
		mode_play_update()
	elseif game_mode=="death" then
		mode_death_update()
	elseif game_mode=="complete" then
		mode_complete_update()
	elseif game_mode=="tally" then
		mode_tally_update()
	elseif game_mode=="cutscene" then
		mode_cutscene_update()
	end
	last_time=current_time
end

function _draw()
	if game_mode=="menu" then
		mode_menu_draw()
	elseif game_mode=="intro" then
		mode_intro_draw()
	elseif game_mode=="start" then
		mode_start_draw()
	elseif game_mode=="play" then
		mode_play_draw()
	elseif game_mode=="death" then
		mode_death_draw()
	elseif game_mode=="complete" then
		mode_complete_draw()
	elseif game_mode=="tally" then
		mode_tally_draw()
	elseif game_mode=="cutscene" then
		mode_cutscene_draw()
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
function center_print(text,xc,y,c,tr)
	local w=#text*4
	local x=xc-w/2-4
	if tr==nil or tr==false then
		rectfill(x-1,y-1,x+w-1,y+5,0)
	end
	print(text,x,y,c)
end

-- change game mode
function change_mode(mode)
	game_mode=mode
	if game_mode=="intro" then
		mode_intro_init()
	elseif game_mode=="start" then
		mode_start_init()
	elseif game_mode=="play" then
		mode_play_init()
	elseif game_mode=="death" then
		mode_death_init()
	elseif game_mode=="complete" then
		mode_complete_init()
	elseif game_mode=="tally" then
		mode_tally_init()
	elseif game_mode=="cutscene" then
		mode_cutscene_init()
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

function draw_box(box,c)
	rectfill(
		box.x,
		box.y,
		box.x+box.width-1,
		box.y+box.height-1,
		c
	)
end

-- draw the current level
function draw_level()
	-- draw level
	for i=-6,level_size/16+6 do
		local x=i*8*16
		if current_level==1 then
			map(0,0,x,24,16,10)
		else
			map(16,0,x,24,16,10)
		end
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
	--sspr(0,0,16,16,max_x-boss_threshold,baseline,8,8)
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
		if amount>0 then
			rectfill(x,y,x+amount,y+4,c)
		end
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
	print(pad(""..player.score,6),x+91,y,7)
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

-- https://www.lexaloffle.com/bbs/?tid=3595
function pad(string,length)
  if (#string==length) return string
  return "0"..pad(string, length-1)
end

-- process all collisions
function process_collisions()
	-- body collisions
	--[[
	for enemy in all(enemies) do
		if collision(enemy.body,player.body) then
			if enemy.kind=="grabguy" then
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
	]]
	-- enemy strikes
	--[[
	for enemy in all(enemies) do
		if collision(enemy.hitbox,player.body) then
			if enemy.kind=="stick_guy" then
				if	enemy.swinging==1 then
					player.health-=enemy.power
					player.hurt=hurt_time
					new_effect("player_hit",enemy.hitbox.x,enemy.hitbox.y)
				end
			end
		end
	end
	]]
	-- projectile collisions
	for projectile in all(projectiles) do
		if collision(projectile.body,player.body) then
			player.hurt=hurt_time
			player.health-=10
			new_effect("player_hit",projectile.x,projectile.y)
			del(projectiles,projectile)
		end
	end

	-- player strikes
	for enemy in all(enemies) do
		if collision(player.hitbox,enemy.body) then
			if is_climax(player.punching) or
					is_climax(player.kicking) then	
				new_effect(
					"enemyhit",
					player.hitbox.x-2,
					player.hitbox.y
				)
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
	local ens={
		'grabguy',
		'knifeguy',
		'stickguy',
		'snake',
		'dragon',
		'ball',
		'mr.x',
	}
	local key=stat(31)
	local num=tonum(key)
	if game_mode=="play" then
		if num~=nil then

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
	if o.position==down then
		o.hitbox.y=o.y+8		
	end
	if (o.jumping>0 and o.kicking>0) then
		o.hitbox.height=16
	end
end

-- ----------------------------
-- effects
-- ----------------------------

function new_effect(kind,x,y)
	effect={
		kind=kind,
		x=x,
		y=y,
		countdown=3,
		done=false,
	}
	effect.update=function(self)
		self.countdown-=1
		if self.countdown<1 then
			del(effects,self)
		end
	end
	effect.draw=function(self)
		if self.kind=="enemy_hit" then
			print("✽",self.x,self.y,7)		
		elseif self.kind=="player_hit" then
			print("✽",self.x,self.y,8)
		elseif self.kind=="break" then
			spr(125,self.x,self.y,1,1)
		end
	end
	add(effects,effect)
end

function init_effects()
	effects={}
end

function update_effects()
	for effect in all(effects) do
		effect:update()
	end
end

function draw_effects()
	for effect in all(effects) do
		effect:draw()
	end
end

-- ----------------------------
-- enemies
-- ----------------------------

function init_enemies()
	enemies={}
	if current_level==1 then
		--new_enemy("stick_guy",min_x)
		new_stickguy(min_x)
	end
end

-- get an x for a new enemy
function random_enemy_x(offset,close)
	local left_x
	local right_x
	-- enemy starts offscreen
	if close==nil or close==false then
		left_x=camera_x-8-offset
		right_x=camera_x+127+7+offset
		-- if too far right use left_x
		if player.x<min_x+boss_threshold then
			x=right_x
		-- if too far left use right_x
		elseif player.x>max_x-boss_threshold then
			x=left_x
		-- else pick a random one
		else
			local	r=flr(rnd(2))
			if r==0 then
				x=right_x
			else
				x=left_x
			end
		end
	-- enemy starts onscreen
	else
		x=flr(rnd(32))+camera_x+64
	end
	return x
end

-- add a group of enemies
function more_enemies()
	if current_level==1 then
		for i=0,2 do
			local x=random_enemy_x(i*16)
			if i==2 and enemy_group_counter>2 then
				new_knifeguy(x)
				enemy_group_counter=0
			else
				new_grabguy(x)
				enemy_group_counter+=1				
			end
		end
	elseif current_level==2 then
		local x=random_enemy_x(0,true)
		if enemy_group_counter==2 then
			new_ball(x)
			enemy_group_counter+=1
		elseif enemy_group_counter==5 then
			new_dragon(x)
			enemy_group_counter=0
		else
			new_snake(x)
			enemy_group_counter+=1
		end
	end
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
		if enemy==nil then
			del(enemies,enemy)
		else
			enemy:update()
		end
	end
end

-- draw all enemies to screen
function draw_enemies()
	for enemy in all(enemies) do
		draw_box(enemy.body,10)
		enemy:draw()
	end
end

-------------------------------
-- enemies 2
-------------------------------

-- grabguy
function new_grabguy(x)
	
	local grabguy={
		kind="grabguy",
		x=x,
		y=baseline,
		state="walking",
		anim=0,
		body={
			x=0,
			y=0,
			width=8,
			height=16
		},
		health=1,
		speed=1.25,
		direction=right,
	}
	
	grabguy.update=function(grabguy)
		grabguy.body.x=grabguy.x+4
		grabguy.body.y=grabguy.y
		if grabguy.health<=0 then
			grabguy.state="dead"
		end
		if grabguy.state=="walking" then	
			if ticks%3==0 then
				grabguy.anim+=1
				if grabguy.anim>1 then
					grabguy.anim=0
				end
			end
			if grabguy.x<player.x then
				grabguy.direction=right
				grabguy.x+=grabguy.speed
			elseif grabguy.x>player.x then
				grabguy.direction=left
				grabguy.x-=grabguy.speed
			end
			if collision(grabguy.body,player.body) then
				grabguy.state="grabbing"
				player.grabbed=3
			end
		elseif grabguy.state=="dead" then
			grabguy.x+=grabguy.direction*-1
			grabguy.y+=gravity
			if grabguy.y>camera_y+127 then
				del(enemies,grabguy)
			end
		end
	end
	
	grabguy.draw=function(grabguy)
		local sprite
		local flip_x
		if grabguy.state=="walking" then
			sprite=100+grabguy.anim*2
		elseif grabguy.state=="grabbing" then
			sprite=104
		elseif grabguy.state=="dead" then
			sprite=106
		end
		if grabguy.x<player.x then
			flip_x=false
		else
			flip_x=true
		end
		spr(sprite,grabguy.x,grabguy.y,2,2,flip_x)
	end
	
	add(enemies,grabguy)
	
end

-- knife guy
function new_knifeguy(x)
	
	local knifeguy={
		x=x,
		y=baseline,
		health=2,
		state="walking",
		body={
			x=0,
			y=0,
			width=8,
			height=16,
		},
		anim=0,
		speed=1.5,
		direction=right,
		attack_height=up,
		throw_time=20
	}
	
	knifeguy.update=function(self)
		if self.health<=0 then
			self.state="dead"
		end
		self.body.x=self.x+4
		self.body.y=self.y
		local target
		local window=8
		if self.x<player.x then
			self.direction=right
			target=player.x-16
		else
			self.direction=left
			target=player.x+15+16
		end
		if self.state=="walking" then
			if ticks%3==0 then
				self.anim+=1
				if self.anim>1 then
					self.anim=0
				end
			end
			if self.x<target-8 then
				self.direction=right
				self.state="walking"
				self.x+=self.speed
			elseif self.x>target+8 then
				self.direction=left
				self.state="walking"
				self.x-=self.speed
			else
				self.state="throwing"
				self.throwing=self.throw_time
				self.cooldown=50
			end
		elseif self.state=="throwing" then
			-- time of release
			if self.throwing==self.throw_time/2 then
				local y=self.y-2
				if self.attack_height==down then
					self.attack_height=up
					y+=10
				else
					self.attack_height=down
				end
				new_projectile(self.x,y,self.direction)
			elseif self.throwing<1 then
				self.state="cooldown"
				self.cooldown=10
			end
			self.throwing-=1
		elseif self.state=="cooldown" then
			if self.cooldown<1 then
				self.state="walking"
			end
			self.cooldown-=1
		elseif self.state=="dead" then
			self.x+=self.direction*-1
			self.y+=gravity
			if self.y>camera_y+127 then
				del(enemies,self)
			end
		end		
	end
	
	knifeguy.draw=function(self)
		local sprite=128
		if self.state=="walking" then
			sprite=128+self.anim*2
		elseif self.state=="throwing" then
			if self.throwing>=self.throw_time/2 then
				sprite=132
			else
				sprite=134
			end
			if self.attack_height==down then
				sprite+=4
			end
		elseif self.state=="dead" then
			sprite=140
		end
		local flip_x
		if self.x<player.x then
			flip_x=false
		else
			flip_x=true
		end
		spr(sprite,self.x,self.y,2,2,flip_x)
	end

	add(enemies,knifeguy)

end

-- stick guy
function new_stickguy(x)

	local stickguy={
		kind="stickguy",
		x=x,
		y=baseline,
		body={
			x=0,
			y=0,
			width=8,
			height=16,
		},
		state="waiting",
		anim=0,
		chain=0,
		swinging=0,
		speed=1.5,
		cooldown=0,
		health=boss_health,
	}
	
	stickguy.update=function(self)
		if self.state=="waiting" then
			if player.x<min_x+boss_threshold then
				self.state="walking"
			end
		elseif self.state=="walking" then
			if ticks%3==0 then
				self.anim+=1
				if self.anim>1 then
					self.anim=0
				end
			end
			if self.cooldown>0 then
				self.x-=self.speed
				self.cooldown-=1
			else
				local target=player.x-8
				local window=2
				if self.x<target-window then
					self.x+=self.speed
				elseif self.x>target+window then
					self.x-=self.speed
				else
					self.state="swinging"
					self.swinging=enemy_strike_time
				end			
			end
		elseif self.state=="swinging" then
			self.swinging-=1
			if self.swinging<1 then
				local n=flr(rnd(2))
				if n==0 then 
					n=-1
				end
				self.position=n
				--update_hitbox(enemy)
				self.swinging=enemy_strike_time
				self.chain+=1
			end
			if self.chain>2 then
				self.chain=0
				self.cooldown=15
				self.position=up
				self.state="walking"
			end
		end
		self.body.x=self.x+4
		self.body.y=self.y
	end
	
	stickguy.draw=function(self)
		local sprite=160
		if self.state=="walking" then
			sprite=160+self.anim*2
		elseif self.state=="swinging" then
			if self.swinging>enemy_strike_time/2 then
				if self.position==up then
					sprite=164
				else
					sprite=168
				end
			else
				if self.position==up then
					sprite=166
				else
					sprite=170
				end
			end
		elseif self.state=="dead" then
			sprite=172
		end
		spr(sprite,self.x,self.y,2,2)
		if self.swinging>0 and self.swinging<5 then
			if self.position==up then
				line(self.x+15,self.y+2,self.x+19,self.y-2,0)
			else
				line(self.x+15,self.y+9,self.x+20,self.y+9,0)				
			end
		end
	end
	
	add(enemies,stickguy)
	
end

-- ball
function new_ball(x)

	local ball={}
	ball.kind="ball"
	ball.x=x
	ball.y=0
	ball.state="falling"
	ball.countdown=50
	ball.anim=0
	ball.body={}
	
	ball.update=function(ball)
		local dest_y=camera_y+48
		if ticks%3==0 then
			ball.anim+=1
			if ball.anim>1 then
				ball.anim=0
			end
		end
		if ball.state=="falling" then
			ball.y+=gravity
			if ball.y>dest_y then
				ball.y=dest_y
				ball.state="countdown"
				ball.start_x=ball.x
				ball.start_y=ball.y
			end
		elseif ball.state=="countdown" then
			if ball.anim==0 then
				ball.x=ball.start_x
				ball.y=ball.start_y
			else
				local x=flr(rnd(2))-1
				local y=flr(rnd(2))-1
				ball.x+=x
				ball.y+=y
			end
			ball.countdown-=1
			if ball.countdown<1 then
				ball.state="exploding"
			end
		end
		ball.body.x=ball.x
		ball.body.y=ball.y
		ball.body.width=8
		ball.body.height=8
	end
	
	ball.draw=function(ball)
		sprite=124
		spr(124,ball.x,ball.y,1,1)
	end

	add(enemies,ball)

end

-- dragon
function new_dragon(x)

	local dragon={}
	dragon.kind="dragon"
	dragon.x=x
	dragon.y=camera_y-8
	dragon.anim=0
	dragon.state="falling"
	dragon.body={}

	dragon.update=function(dragon)
		local bottom=baseline
		if dragon.state=="falling" then
			dragon.y+=gravity
			if dragon.y>bottom then
				dragon.y=bottom
				dragon.state="appearing"
			end
		elseif dragon.state=="appearing" then
			if ticks%3 then
				dragon.anim+=1
				if dragon.anim>5 then
					dragon.state="breathing"
				end
			end
		end		
		dragon.body.x=0
		dragon.body.y=0
		dragon.body.width=0
		dragon.body.height=0
	end
	
	dragon.draw=function(dragon)
		local sprite
		local width
		if dragon.state=="falling" then
			sprite=72
			width=1
		elseif dragon.state=="appearing" then
			sprite=73+dragon.anim
			if dragon.anim>3 then
				width=2
			else
				width=1
			end
		elseif dragon.state=="breathing" then
			sprite=78
			width=2
		end
		local flip_x
		if dragon.x<player.x then
			flip_x=false
		else
			flip_x=true
		end
		spr(sprite,dragon.x,dragon.y,width,2,flip_x)
		--[[
		if enemy.fire>0 then
			local x
			if enemy.x<player.x then
				x=enemy.x+16
			else
				x=enemy.x-16
			end
			spr(108,x,enemy.y,2,1,enemy.flip_x)
		end
		]]
	end
	
	add(enemies,dragon)

end

-- snake
function new_snake(x)

	local snake={}
	snake.kind="snake"
	snake.x=x
	snake.y=camera_y-8
	snake.speed=2
	snake.anim=0
	snake.health=1
	snake.breaking=0
	snake.state="falling"
	snake.body={}
	update_body(snake)

	snake.update=function(snake)
		local enemy=snake
		local bottom=baseline+8
		if ticks%3==0 then
			enemy.anim+=1
			if enemy.anim>1 then
				enemy.anim=0
			end
		end
		if enemy.state=="falling" then
			enemy.y+=gravity
			if enemy.y>bottom then
				sfx(11)
				enemy.y=bottom
				enemy.state="breaking"
				enemy.breaking=5
			end
		elseif enemy.state=="breaking" then
			enemy.breaking-=1
			if enemy.breaking<1 then
				enemy.state="active"
			end
		elseif enemy.state=="active" then
			if enemy.locked_direction==nil then
				if enemy.x<player.x then
					enemy.locked_direction=right
				else
					enemy.locked_direction=left
				end
			end
			enemy.x+=enemy.speed*enemy.locked_direction
		end		
		enemy.body.x=enemy.x
		enemy.body.y=enemy.y
		enemy.body.width=8
		enemy.body.height=8
	end
	
	snake.draw=function(snake)
		local sprite
		if snake.state=="falling" then
			sprite=110
		elseif snake.state=="breaking" then
			sprite=111
		elseif snake.state=="active" then
			sprite=126+snake.anim		
		end
		local flip_x
		if snake.locked_direction==left then
			flip_x=true
		else
			flip_x=false
		end
		if test_mode and show_enemy_bodies then
			draw_box(snake.body,15)
		end
		spr(sprite,snake.x,snake.y,1,1,flip_x)
	end
	
	add(enemies,snake)

end
	
-- ----------------------------
-- player
-- ----------------------------

function new_player()

	player={
		score=0,
		health=100,
		y=baseline,
		grabbed=0,
		jumping=0,
		kicking=0,
		punching=0,
		hurt=0,
		speed=1,
		w_index=0,
		body={
			x=0,
			y=0,
			width=8,
			height=16
		}
	}

	if current_level%2==1 then
		player.x=max_x-16
		player.direction=left
	else
		player.x=0
		player.direction=right
	end
	
	player.update_complete=function(self)
		self.stepping=false
		if (current_level%2==0 and self.x<max_x) or
				(current_level%2==1 and self.x>min_x-3) then
			self.walking=true
			self.stepping=false
			self.x+=complete_direction*1
		else
			self.walking=false
			self.stepping=true
			if self.w_index==1 then
				self.x+=complete_direction*2
				self.y-=2
			end
		end
	end

	player.update_death=function(self)
		if self.direction==left then
			self.x+=gravity/2
		else
			self.x-=gravity/2
		end
		self.y+=gravity
		if self.y>camera_y+128 then
			change_mode("start")
		end
	end

	player.update_start=function(self)
		self.walking=true
		self.x+=player.speed*player.direction
	end
	
	player.update=function(self)
		self.body.x=self.x+4
		self.body.y=self.y		
		update_hitbox(self)
		player_input()
		if ticks%3==0 then
			self.w_index+=1
			if self.w_index>1 then
				self.w_index=0
			end
		end	
		if self.last_direction~=self.direction then
			self.grabbed-=1
			if self.grabbed<0 then
				self.grabbed=0
			end		
		end
		-- lose health if grabbed
		if self.grabbed>0 then
				self.health-=0.5
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
		local grabbers=0
		for enemy in all(enemies) do
			if enemy.grabbing==true then
				grabbers+=1
				break
			end
		end
		if grabbers==0 then
			self.grabbed=0
		end
		-- apply gravity/momentum
		if self.jumping>0 then
			self.x+=self.jump_dir*self.speed
		end
		if self.jumping>jump_max/2 then
			self.y-=gravity
		else
			self.y+=gravity
			if self.y>baseline then
				self.y=baseline
			end
		end
		self.kicking-=1
		if self.kicking<0 then
			self.kicking=0
		end
		self.punching-=1
		if self.punching<0 then
			self.punching=0
		end
		self.jumping-=1
		if self.jumping<0 then
			self.jumping=0
		end
		-- if player is hurt
		if self.hurt>0 then
			self.hurt-=1
		end
		-- if no health left then die
		if self.health<=0 then
			if test_mode==false then
				change_mode("death")
			end
		end
		-- if we're at end of level
		if (current_level%2==1 and self.x<=min_x) or
				(current_level%2==0 and self.x+15>=max_x) then
			change_mode("complete")
		end
		self.last_direction=player.direction
	end
	
	player.draw=function(self)
		local sprite
		-- player hurt sprite
		if player.hurt>0 then
			sprite=36
		-- jumping
		elseif player.jumping>0 then
			sprite=6
			if player.jumping>jump_max-4 then
				sprite=2
			end
			-- if kicking
			if player.kicking>0 then
				sprite=44
				-- if climax of kick
				if is_climax(player.kicking) then
					sprite=38
				end
			-- if punching
			elseif player.punching>0 then
				sprite=44
				-- if climax of punch
				if is_climax(player.punching) then
					sprite=40
				end	
			end				
		-- ducking
		elseif player.position==down then
			-- default ducking sprite
			sprite=14
			-- if kicking
			if player.kicking>0 then
				sprite=32
				-- if climax of kick
				if is_climax(player.kicking) then
   		sprite=42
   	end
 		-- if punching
  	elseif player.punching>0 then
  		sprite=32
  		-- if climax of punch
  		if is_climax(player.punching) then
  			sprite=34
  		end
  	end
		-- walking
		elseif player.walking==true then
			sprite=player.w_index*2
		-- stepping
		elseif player.stepping then
			sprite=2+player.w_index*2
		-- in normal state
		else
			-- if kicking
			if player.kicking>0 then
				sprite=10
				-- if climax of kick
				if is_climax(player.kicking) then
					sprite=8
				end
			-- if punching
			elseif player.punching>0 then
				sprite=10
				-- if climax of punch
				if is_climax(player.punching) then
					sprite=12
				end
			end
		end
		-- flip if looking left
		local flip_x=false
		if self.direction==left then
			flip_x=true
		end
		-- draw the sprite
		spr(sprite,self.x,self.y,2,2,flip_x)
	end

end

function init_player()
	new_player()
	--[[
	local score=0
	if player~=nil then
		score=player.score	
	end
	player=new_entity()
	player.score=score
	player.health=100
	player.y=baseline
	player.grabbed=0
	player.jumping=0
	player.kicking=0
	player.punching=0
	update_body(player)
	update_hitbox(player)
	if current_level%2==1 then
		player.x=max_x-16
		player.direction=left
	else
		player.x=0
		player.direction=right
	end
	]]
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

--[[
function update_player()

	if ticks%5==0 then
		player.w_index+=1
		if player.w_index>1 then
			player.w_index=0
		end
	end	
	
	if game_mode=="start" then
		player.walking=true
		player.x+=player.speed*player.direction
	
	-- play mode
	elseif game_mode=="play" then
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
		local grabbers=0
		for enemy in all(enemies) do
			if enemy.grabbing==true then
				grabbers+=1
				break
			end
		end
		if grabbers==0 then
			player.grabbed=0
		end
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
				change_mode("death")
			end
		end
		-- if we're at end of level
		if (current_level%2==1 and player.x<=min_x) or
				(current_level%2==0 and player.x+15>=max_x) then
			change_mode("complete")
		end
		player.last_direction=player.direction

	elseif game_mode=="death" then
		if player.direction==left then
			player.x+=gravity/2
		else
			player.x-=gravity/2
		end
		player.y+=gravity
		if player.y>camera_y+128 then
			change_mode("start")
		end				

	elseif game_mode=="complete" then
		player.stepping=false
		if (current_level%2==0 and player.x<max_x) or
				(current_level%2==1 and player.x>min_x-3) then
			player.walking=true
			player.stepping=false
			player.x+=complete_direction*1
		else
			player.walking=false
			player.stepping=true
			if player.w_index==1 then
				player.x+=complete_direction*2
				player.y-=2
			end
		end
	
	end
	
end
]]

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
	local sprite=0

	-- dead sprite
	if game_mode=="death" then
		sprite=46

	-- player hurt sprite
	elseif player.hurt>0 then
		sprite=36

	-- jumping
	elseif player.jumping>0 then
		sprite=6
		if player.jumping>jump_max-4 then
			sprite=2
		end
		-- if kicking
		if player.kicking>0 then
			sprite=44
			-- if climax of kick
			if is_climax(player.kicking) then
				sprite=38
			end
		-- if punching
		elseif player.punching>0 then
			sprite=44
			-- if climax of punch
			if is_climax(player.punching) then
				sprite=40
			end	
		end
						
	-- ducking
	elseif player.position==down then
		-- default ducking sprite
		sprite=14
		-- if kicking
		if player.kicking>0 then
			sprite=32
			-- if climax of kick
			if is_climax(player.kicking) then
   	sprite=42
   end
  -- if punching
  elseif player.punching>0 then
  	sprite=32
  	-- if climax of punch
  	if is_climax(player.punching) then
  		sprite=34
  	end
  end
  
	-- walking
	elseif player.walking==true then
		sprite=player.w_index*2
		
	-- stepping
	elseif player.stepping then
		sprite=2+player.w_index*2
		
	-- in normal state
	else
		-- if kicking
		if player.kicking>0 then
			sprite=10
			-- if climax of kick
			if is_climax(player.kicking) then
				sprite=8
			end
		-- if punching
		elseif player.punching>0 then
			sprite=10
			-- if climax of punch
			if is_climax(player.punching) then
				sprite=12
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
		sprite,
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

function new_projectile(x,y,d)
		local projectile={
			x=x,
			y=y,
			body={
				x=0,
				y=0,
				width=8,
				height=8
			},
			direction=d,		
		}
		projectile.update=function(self)
			debug(self.direction)
			self.x+=self.direction*2
			self.body.x=self.x
			self.body.y=self.y
			if (self.direction==right and self.x>camera_x+128) or
					(self.direction==left and self.x<-8) then
				del(projectiles,projectile)	
			end			
		end
		projectile.draw=function(self)
			local flip_x
			if self.direction==right then
				flip_x=false
			else
				flip_x=true
			end
			spr(98,self.x,self.y,1,1,flip_x)
		end
		add(projectiles,projectile)
end

function init_projectiles()
	projectiles={}
end

function update_projectiles()
	for projectile in all(projectiles) do
		projectile:update()
	end
end

function draw_projectiles()
	for projectile in all(projectiles) do
		projectile:draw()
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
		update_camera(complete_x,camera_y)
	else
		music(-1)
		update_player()
	end
	if complete_timer>120 then
		change_mode("tally")
	end
	complete_timer+=1
end

function mode_complete_draw()
	cls(12)
	draw_level()
	draw_player()
	draw_osd()
end

-- cut scene program

function mode_cutscene_init()
	cutscene_flash=false
	cutscene_timer=0
	music(5)
end

function mode_cutscene_update()
	if ticks%8==0 then
		cutscene_flash=not cutscene_flash
	end
	if cutscene_timer>149 then
		change_mode("start")
	end
	cutscene_timer+=1
end

function mode_cutscene_draw()
	cls(12)
	rectfill(0,0,127,23,0)
	map(16,7,0,baseline+15,16,3)
	center_print("save sylvia from mr.x",66,32,7,true)
	if cutscene_flash then
		cursor(8,48)
		color(7)
		print("help me")
		cursor(8,56)
		print("thomas!")
	end
	if cutscene_timer>100 then
		cursor(90,56)
		print("sylvia!")
	end
	spr(174,16,baseline,2,2)
	player.x=127-32
	player.y=baseline
	player.walking=true
	update_player()	
	draw_player()
	rectfill(0,104,127,127,0)
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
		change_mode("start")
	end
end

function mode_intro_draw()
	cls(12)
	draw_level()
	draw_player()
	camera(camera_x,camera_y)
	local xc=camera_x+64
	center_print("level "..current_level,xc,50,7,false)
	draw_osd()
end

-- menu program

function mode_menu_update()
	if btn(4) and btn(5) then
		if skip_cutscene then
			change_mode("start")
		else
			change_mode("cutscene")
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
	--update_player()
	player:update()
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
	--draw_player()
	player:draw()
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
	--update_player()
	player:update()
	start_timer-=1
	if start_timer<1 then
		change_mode("play")
	end
end

function mode_start_draw()
	cls(12)
	draw_level()
	draw_player()
	update_camera()
	local xc=camera_x+64
	center_print("level "..current_level,xc,50,7,false)
	draw_osd()
end

-- tally program

function mode_tally_init()
end

function mode_tally_update()
	level_timer-=10
	player.score+=10
	sfx(14)
	if level_timer<1 then
		current_level+=1
		change_mode("start")
	end
end

function mode_tally_draw()
	draw_osd()
end
__gfx__
ccccccc0000cccccccccccc0000cccccccccccc0000ccccccccccccccccccccccccccc0000cccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccc0999cccccccccccc0999cccccccccccc0999cccccccccccc0000ccccccccccc0999cccccccccccccc0000cccccccccccccc0000ccccccccccccccccccc
cccccc0919cccccccccccc0919cccccccccccc0919ccccccccccc0999cccccccccccc0919ccccccccccccc0999cccccccccccccc0999cccccccccccccccccccc
cccccc9999cccccccccccc9999cccccccccccc9999ccccccccccc0919ccccccccccccc999ccccccccccccc0919cccccccccccccc0919cccccccccccccccccccc
cccccc799ccccccccccccc799ccccccccccccc799cccccccccccc0999cc9ccccccccc799ccccc700ccccccc999cc9cccccccccccc999ccccccccccc0000ccccc
ccccc00770ccccccccccc70077ccccccccccc00770ccccccccccc7777cc9cccccccc770970cc7790cccccc00779c9ccccccccccc07700999cccccc0999cccccc
cccc000077ccccccccccc00077cccccccccc000077cccccccccc00797099ccccccc0007007077790ccccc70009909cccccccccc0770009c9cccccc0919cccccc
cccc9007770cccccccccc0097ccccccccccc9007770ccccccccc0099809cccccccc0007798877cccccccc70999099cccccccccc07700ccccccccccc999cccccc
cccc99777c99ccccccccc09988cccccccccc99777c99cccccccc099887cccccccccc09999878cccccccccc7799cccccccccccccc7777ccccccccc00790cccccc
ccccc9988cc99ccccccccc99878cccccccccc99887799cccccccc987787cccccccccc999877cccccccccccc8888cccccccccccc8888ccccccccc0077770ccccc
ccccc79978ccccccccccccc997ccccccccccc7997777cccccccccc777777ccccccccccc777ccccccccccccc77878ccccccccccc77777cccccccc0077770ccccc
cccccc67777cccccccccccc777cccccccccccc766777ccccccccccc77c77ccccccccccc777cccccccccccc777c777ccccccccc777c777ccccccc9958899ccccc
ccccc776677cccccccccccc777ccccccccccc777c099cccccccccc777c99cccccccccccc77ccccccccccc777ccc77cccccccc777ccc77cccccccc998798ccccc
cccc777cc777cccccccccc777ccccccccccc777ccc000ccccccccc77cc000ccccccccccc777ccccccccc777ccc777ccccccc777ccc777ccccccc77977777cccc
ccc099cccc990ccccccccc99ccccccccccc099cccccccccccccccc99ccccccccccccccccc99ccccccccc99cccc99cccccccc99cccc99cccccccc997cc799cccc
ccc0000ccc00cccccccccc000cccccccccc0000ccccccccccccccc000ccccccccccccccc000ccccccccc000ccc000ccccccc000ccc000cccccc000cccc000ccc
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
ccccccccbbbbbb368888888888888888ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc77ccccccc7aa3333c38cccccccaa3333c38cc
ccccccccbbbbb36baaa8aaaa8a8aaaaacccccccccccccccccccccccccccccccccccccccccccccccccccccccccc7777ccccc79833883833ccccccc833883833cc
ccccccccbbbb36bbccc8a88a8a8a88a8ccccccccccccccccccccccccccccccccccccccccccccccccccccccccc7d77d7ccccc8c833333c7cccccc8c833333c7cc
ccccccccbbb36bbbccc8a8888a8888a8ccccccccccccccccccccccccccccccccccccccccccccccccccccccccc777777cccccc7c83ac7ccccccccc8c83ac7cccc
ccccccccbb36bbbbccc8aaaa8a8aaaa8cccccccccccccccccccccccccccccccccccccccccccccccccccccccccc7777ccccccccc73aac7cc7ccccccc83aaccccc
ccccccccb36bbbbbccc888888a888888ccccccccccccccccccccccccccccccccccccccccccccccccc7d77d7cc7d77d7ccccccc8c83b797cccccccc8c83baaccc
cccccccc33333333cccccccc8a8ccccccccccccccccccccccccccccccccccccccccccccccccccccc7777777777777777cccc7cccc3337accccccccccc333bacc
cccccccc00000000cccccccc8a8ccccccccccccccccccccccccccccccccccccccccccccccccccccc7777777777777777ccc797ccc8383bacccccccccc8383bac
ffffffff7ccccccccccccccc8a8cccccccccccccccccccccccccccccccccccccccffffccccccccccd777777dd777777dcccc7ccc7c373baccccccccccc383bac
4444444467cccccccccccccc8a8ccccccccccccccccccccccccccccccccccccccbffff8ccccccccccdd77ddccdd77ddccccccc8cc833bbaccccccc8cc833bbac
ffffffffc67cccccaaaaaaaaaaaaaaaaccccccccccccccccccccccccccccccccfbbff88fcc7777cccc7777cccc7777cccccc8c8ccc3bbacccccc8c8ccc3bbacc
ffffffff44ffffff8888888888888888ccccccccccccccccccccccccccccccccffbb88ffc777777cc777777cc777777cccccc8a8c3bb7cccccccc8a8c3bbaccc
44444444ccc555ccaaaaaaaaaaaaaaaaccccccccccccccccccccccccccccccccfff88fff777777777777777777777777ccc87aa338b797ccccc88aa338bacccc
ffffffffcccc67ccccccccccccccccccccccccccccccccccccccccccccccccccff88bbff77d77d7777d77d7777d77d77ccccc8333bac7cccccccc8333baccccc
ffffffffccccc67cccccccccccccccccccccccccccccccccccccccccccccccccc88ffbbcc77dd77cc77dd77cc77dd77ccccccc7c79997c7ccccccccc3acccccc
ffffffffcccccc67ccccccccccccccccccccccccccccccccccccccccccccccccccffffcccc7777cccc7777cccc7777ccccccccccc777cccccccccccccccccccc
4444444444444444cccccccc88888888ccccccc2222cccccccccccc2222cccccccccccc2222cccccccccccccccccccccccccc8cc8cc8c8cccccaaccccccccccc
8888888888888888cccccccca8aaaaaacccccc2999cccccccccccc2999cccccccccccc2999ccccccccccccccccccccccccc88aa8acaa8aaccca33acccccccccc
8aaaaaa88aaaaaa8cc1ccccca8cccccccccccc2929cccccccccccc2929cccccccccccc2929cccccccc4cccccccccccccc88aa7777a77a777ccbaabccccccc8cc
8a8888a88a8888a844177777a8cccccccccccc9999cccccccccccc9999cccccccccccc9999ccccccc499ccccc99ccccc8a7777777777778cca3bb3acbcc8cccb
8a8aaaa88aaaa8a84417777ca8cccccccccccc299ccccccccccccc299ccccccccccccc299cccccccc4999cccc99cccccc88aa7777a77a777cba33abcc8cccc8c
8a888888888888a8cc1ccccc88ccccccccccc2f222cccccccccccff22fccccccccccccff22ccccccc4499cffffccccccccc88aa8acaa8aacc3baab3ccb3cc3bc
8aaaaaaaaaaaaaa8cccccccccccccccccccccfff22ccccccccccfff222fcccccccccccfff2c99ccccc42222ffcccccccccccc8cc8cc8c8cccc3bb3cc3c8338c3
8888888888888888cccccccccccccccccccccfff2299ccccccccff2222fccccccccccccffff99cccccff2222ccccccccccccccccccccccccccc33cccc3b88b3c
111111111122221188888888ccffccccccccccf99299ccccccccff2222f99cccccccccc2fffcccccccff2222ffccccccccffeecccccc7ccccccccccccccccccc
11111111118e8811aaaaaaaaccffccccccccccf99fccccccccccf9922cc99ccccccccccfffccccccccff222ffffccccccfeeffecc77cc77ccccc33cccccc33cc
1c1c1c1c118e8811ccccccccf4ff4fffcccccccfffccccccccccc99fffcccccccccccccfffccccccccffc2fff2fccccceeffeeffc7fcff7cccc3333cccc3333c
c1c1c1c1c18e8811ccccccccf4ff4fffcccccccfffccccccccccccfffffccccccccccccfffcccccccccf99ff2ffccccceeffeeff7ccccfccccc37cccccc377cc
1ccc1ccc17888871ccccccccccffccccccccccffffcccccccccccffffffcccccccccccffffcccccccccc99ff29ffccccffeeffeeccfcccc7cccc37cccccc337c
cc1ccc1c11777711ccccccccccffccccccccc29ffcccccccccccfffccfffccccccccccfffccccccccccccccc29fffcccffeeffeec7ffcf7ccc88c37ccccccc37
ccccccccc111111cccccccccccffccccccccc29cccccccccccc299cccc99cccccccccc299ccccccccccccccc2cf299ccceffeefcc77cc77cc833837cc8888c37
ccccccccccccccccccccccccccffccccccccc222ccccccccccc2222ccc222ccccccccc2222ccccccccccccccccc2222ccceeffccccc7cccc83c337cc83c3337c
ccccccc1111cccccccccccc1111ccccc777199c1111cccccccccccc1111cccccccccccc1111ccccccccccccccccccccccccccccccccccccccccccc44444ccccc
cccccc7777cccccccccccc7777cccccccc71997777cccccccccc7c7777cccccccccccc7777cccccccccccccc1111ccccccccccccccccccccccccc44fff44cccc
ccccc71919ccccccccccc71919ccccccccc1c71919ccccccccccc71919ccccccccccc71919ccccccccccc7c7777cccccccc1ccccccccccccccccc44f1fcccccc
cccccc9999cccccccccc7c9999ccccccccccc79999cccccccccccc9999ccccccccccc79999cccccccccccc71919ccccccc177ccccc99ccccccccc44fffcccccc
cccccc199ccccccccccccc199cccccccccccc7199ccccccccccccc199cccccccccccc7199cccccccccccccc9999ccccccc7999cccc99ccccccccc488fccccccc
ccccc77117ccccccccccc17111ccccccccccc11111ccccccccccc7711777799cccccc11111ccccccccccccc199cccccccc7199c7777cccccccccc4ff88fccccc
cccc7771117cccccccccc77711ccccccccccc17711cccccccccc7771117779ccccccc17711ccccccccccc77111ccccccc7c1111177cccccccccccc8ff8fccccc
cccc7711117cccccccccc7771199ccccccccc1777799cccccccc7711117ccccccccc71777799cccccccc7771117cccccccc771111cccccccccccccc8fffccccc
cccc771111799ccccccccc799199cccccccccc177799cccccccc771111cccccc777191177799cccccccc77111177ccccccc77111177ccccccccccc888fcccccc
cccc79911cc99ccccccccc7997cccccccccccc1111cccccccccc79911ccccccccc71991111cccccccccc79911cc799ccccc771117777cccccccccc8888cccccc
ccccc99777ccccccccccccc777ccccccccccccc777ccccccccccc997777cccccccc1ccc777ccccccccccc997777c99ccccc77c777717ccccccccccc888cccccc
cccccc77777cccccccccccc777ccccccccccccc777cccccccccccc777777ccccccccccc777cccccccccccc777777cccccccc79977177ccccccccccc888cccccc
ccccc777777ccccccccccc7777cccccccccccc7777ccccccccccc777c777cccccccccc7777ccccccccccc777c777ccccccccc99771977cccccccccc8f8cccccc
cccc777cc777ccccccccc1977cccccccccccc1977ccccccccccc777ccc77ccccccccc1977ccccccccccc777ccc77ccccccccccccc19777cccccccccffccccccc
ccc199cccc99ccccccccc19cccccccccccccc19cccccccccccc199ccc199ccccccccc19cccccccccccc199ccc199ccccccccccccc1c7199cccccc8f8ffcccccc
ccc1111ccc111cccccccc111ccccccccccccc111ccccccccccc1111ccc111cccccccc111ccccccccccc1111ccc111ccccccccccccccc1111ccccc88c888ccccc
cccccccc4444cccccccccccc4444cccc000009904444cccccccccccc4444ccccccc0ccccccccccccccccccccccccccccccccccc0cccccccccccccccccccccccc
ccccccc4999cccccccccccc4999cccccccccc994999cccccccccccc4999ccccccccc0ccccccccccccccccccccccccccccccccccc0ccccccccccccccccccccccc
ccccccc4919cccccccccccc4919c0ccccccccc64919cccccccccccc4919cccccccccc0ccccccccccccccccccccccccccccc4ccccc0ccccccccccc44444cccccc
ccccccc9999cc0ccccccccc9999c0ccccccccc69999cccccccccccc9999cc99ccccccc0cc4444cccccccccccc4444ccccc499ccccc99cccccccc44fff44ccccc
ccccccc499ccc0ccccccccc499cc0ccccccccc6499ccccccccccccc499cc609cccccccc94999cccccccccccc4999cccccc4999cccc99cccccccc44f1fccccccc
cccccc66446cc0cccccccc46444c0ccccccccc44444ccccccccccc66446606ccccccccc949196ccccccccccc4919cccccc4499c6666c0ccccccc44fffccccccc
ccccc6664446c0cccccccc66644c0ccccccccc46644cccccccccc66644466ccccccccccc99996ccccccccccc9999ccccccc4444466ccc0cccccc488fcccccccc
ccccc6644446c0cccccccc6664499ccccccccc4666699cccccccc6644446cccccccccccc49966ccccccccccc499cccccccc664444cccccccccccf8888ccccccc
ccccc664444699ccccccccc699499cccccccccc466699cccccccc664444ccccccccccc664446cccccccccc6644466699ccc66444466cccccccc0ff888ccccccc
ccccc69944cc99ccccccccc6996c0cccccccccc4444cccccccccc69944ccccccccccc666444cccccccccc66644460090ccc664446666ccccccc00000cccccccc
cccccc99666cc0cccccccccc666ccccccccccccc666ccccccccccc996666ccccccccc6644466ccccccccc6644466ccccccc66c666646ccccccc0f888888ccccc
ccccccc66666cccccccccccc666ccccccccccccc666cccccccccccc666666cccccccc69946666cccccccc69946666ccccccc69966466ccccccc088fff8f8cccc
cccccc666666ccccccccccc6666cccccccccccc6666ccccccccccc666c666ccccccccc9966666ccccccccc9966666cccccccc99664966cccccc00088fffccccc
ccccc666cc666ccccccccc4966cccccccccccc4966ccccccccccc666ccc66cccccccc6666cc66cccccccc6666cc66cccccccccccc49666ccccc0c0c8fffccccc
cccc499cccc99ccccccccc49cccccccccccccc49cccccccccccc499ccc499ccccccc499ccc499ccccccc499ccc499cccccccccccc4c6499cccc0c0ccfcf8cccc
cccc4444ccc444cccccccc444ccccccccccccc444ccccccccccc4444ccc444cccccc4444ccc444cccccc4444ccc444cccccccccccccc4444ccc0cccc88888ccc
ccccccc4444cccccccccccc4444ccccccccccccccccccccccccccccccccccccccccccc4444cccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccc4999cccccccccccc4999cccccccccccccccccccccccccccc4444ccccccccccc4999cccccccccccccc4444cccccccccccccc4444ccccccccccccccccccc
cccccc4939cccccccccccc4939ccccccccccccccccccccccccccc4999cccccccccccc4939ccccccccccccc4999cccccccccccccc4999cccccccccccccccccccc
cccccc9999cccccccccccc9999ccccccccccccccccccccccccccc4939ccccccccccccc999ccccccccccccc4939cccccccccccccc4939cccccccccccccccccccc
cccccc099ccccccccccccc099cccccccccccccccccccccccccccc4999cc9ccccccccc099ccccc088ccccccc999cc9cccccccccccc999ccccccccccc4444ccccc
ccccc88008ccccccccccc08800ccccccccccccccccccccccccccc0000cc9cccccccc008908cc0098cccccc88009c9ccccccccccc80088999cccccc4999cccccc
cccc888800ccccccccccc88800cccccccccccccccccccccccccc88090899ccccccc8880880800098ccccc08889989cccccccccc8008889c9cccccc4939cccccc
cccc9880008cccccccccc8890ccccccccccccccccccccccccccc8899889cccccccc8880098800cccccccc08999899cccccccccc80088ccccccccccc999cccccc
cccc99000c99ccccccccc89988cccccccccccccccccccccccccc899880cccccccccc89999808cccccccccc0099cccccccccccccc0000ccccccccc88098cccccc
ccccc9988cc99ccccccccc99808cccccccccccccccccccccccccc980080cccccccccc999800cccccccccccc8888cccccccccccc8888ccccccccc8800008ccccc
ccccc09908ccccccccccccc990cccccccccccccccccccccccccccc000000ccccccccccc000ccccccccccccc00808ccccccccccc00000cccccccc8800008ccccc
cccccc50000cccccccccccc000cccccccccccccccccccccccccccc000c00ccccccccccc000cccccccccccc000c000ccccccccc000c000ccccccc9988899ccccc
ccccc005500ccccccccccc0000ccccccccccccccccccccccccccc0000c99cccccccccccc00ccccccccccc000ccc00cccccccc000ccc00cccccccc998098ccccc
cccc000cc000ccccccccc8900ccccccccccccccccccccccccccc8900cc888ccccccccccc000ccccccccc000ccc000ccccccc000ccc000ccccccc00900000cccc
ccc899cccc99ccccccccc89ccccccccccccccccccccccccccccc89ccccccccccccccccccc99ccccccccc99cccc99cccccccc99cccc99cccccccc990cc099cccc
ccc8888ccc888cccccccc8cccccccccccccccccccccccccccccc8ccccccccccccccccccc888ccccccccc888ccc888ccccccc888ccc888cccccc888cccc888ccc
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
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001010101010101010000000000000000010101010101010100000000000000000101010100000000000000000000000001010101000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000020202020202020202020202020200000202020202020202020202020002000000000000010100000000000000000000000000000101000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
4141414141414141414141414141414141414141414141414141414141414141404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040
4243727242437272424372724243727242437272424372724243727242437272404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040
5253525252535252525352525253525252535252525352525253525252535252404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040
4040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040
4040404040404040404040404040404040404040404040574040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040
4040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040
4040404040404040404040404057405740574057404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040
5050505050505050505050505050505050505050505050505050505050505050404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040
6061606160616061606160616061606160616061606160616061606160616061404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040
7170707071707070717070707170707041414141414141414141414141414141404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040
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
010c0000073650030507365053650736500305073650536507365003050736505365073650a3650736505365073650030507365053650736500305073650536507365003050736505365073650a3650736505365
010c00000c365003050c3650a3650c365003050c3650a3650c365003050c3650a3650c3650f3650c3650a3650c365003050c3650a3650c365003050c3650a3650c365003050c3650a3650c3650f3650c3650a365
010c00000e365000000e3650c3650e365000000e3650c3650e365000000e3650c3650e365113650e3650c3650c365000000c3650a3650c365000000c3650a3650c365000000c3650a3650c3650f3650c3650a365
010c00000066500005006650066500665000050066500665006650000500665006650066500005006650066500665000050066500665006650000500665006650066500005006650066500665000050066500665
011000001a460184601546013460114600e460114600e4000e4000e4600e400004001a460184601546013460114600e4601146000400004000e46000400004001a460184601546013460114600e4601146000400
01100000004000e46000400004000c4600e4000e46000400004000040000400004000040000400004000040000400004000040000400004000040000400004000040000400004000040000400004000040000400
011000001f4601d4601a4601846016460134601646013400074001346000400004001f4601d4601a4601846016460134601646000400004001346000400004001f4601d4601a4601846016460134601646000400
011000000040013460004000040011460004001346000400004000040000400004000040000400004000040000400004000040000400004000040000400004000040000400004000040000400004000040000400
01060000136752560003675216001367518600036750f600136752560003675216001367518600036750f600136752560003675216001367518600036750f600136752560003675216001367518600036750f600
010800003167424674006040060400604006040060400604006040060400604006040060400604006040060400604006040060400604006040060400604006040060400604006040060400604006040060400604
010c00002867500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005
000100003445033450334503345033450344503545037450384503a4503b45030450324503445035450384503b4503145033450354503745039450304503245035450384503b4503045032450334503245033450
011000001364500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005
010500000364500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005
00040000320501e050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
01 00034344
00 00034344
00 01034344
00 00034344
02 02034344
01 04064844
00 05074844

