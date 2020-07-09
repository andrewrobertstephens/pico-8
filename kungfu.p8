pico-8 cartridge // http://www.pico-8.com
version 27
__lua__
-- ===================
-- kung fu
-- andrew stephens
-- june 2020
-- version 0.1
-- ===================

test_mode=true
no_enemies=true
show_enemy_bodies=true
show_enemy_hitboxes=true
show_player_body=true
show_player_hitbox=true
skip_cutscene=true
logfile="kungfu"

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
jump_max=10
level_size=80
strike_duration=8
strike_contact=6
strike_hold=2
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
levels={}
levels[1]={
	boss="stickguy",
	delay=100,
	offset=8,
	sequence={
		{"grabguy","grabguy","grabguy"},
		{"grabguy","grabguy","grabguy"},
		{"grabguy","grabguy","grabguy"},
		{"knifeguy"}
	}
}
levels[2]={
	boss="boomerangguy",
	delay=50,
	offset=8,
	sequence={
		{"snake"},
		{"snake"},
		{"ball"},
		{"snake"},
		{"snake"},
		{"dragon"}
	}
}
current_level=2

palt(0,false)
palt(12,true)

-- ----------------------------
-- pico-8 main callbacks
-- ----------------------------

function _init()	
	-- enable full keys if testing
	if test_mode then
		poke(0x5f2d,1)
	end
	init_player()
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
		if is_even(current_level) then
			spr(81,max_x+48-i*8,33+i*8,1,1,true)
		else
			spr(81,-48+i*8,33+i*8,1,1)
		end
	end
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
	if enemies~=nil then
		--debug(#enemies)
	end
end

-- is even
function is_even(n)
	return n%2==0
end

-- is odd
function is_odd(n)
	return n%2==1
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
			if projectile.kind~=nil and 
					projectile.kind~="boomerang" then
				del(projectiles,projectile)
			end
		end
	end

	-- player strikes
	for enemy in all(enemies) do
		if collision(player.hitbox,enemy.body) then
			if is_climax(player.punching) or
					is_climax(player.kicking) then	
				new_effect(
					"enemy_hit",
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
		'ball',
		'dragon',
		'boomerangguy',
		'mr.x',
	}
	local key=stat(31)
	local num=tonum(key)
	if game_mode=="play" then
		if num~=nil then
			local en=ens[num]
			new_enemy(en)
		end
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

-- ----------------------------
-- effects
-- ----------------------------

function new_effect(kind,x,y)
	if effects==nil then
		effects={}
	end
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

-- update all enemy movements
function update_enemies()
	for enemy in all(enemies) do
		enemy:update()
		if enemy.state=="dead" and
				enemy.scored==false then
			player.score+=enemy.value
			player.scored=true
		end
	end
end

-- draw all enemies to screen
function draw_enemies()
	for enemy in all(enemies) do
		if test_mode then
			if show_enemy_bodies then
				draw_box(enemy.body,10)
			end
			if show_enemy_hitboxes then
				if enemy.hitbox~=nil then
					draw_box(enemy.hitbox,10)
				end
			end
		end
		enemy:draw()
	end
end

-------------------------------
-- enemies 2
-------------------------------

-- catchall function
function new_enemy(kind,offset)
	if enemies==nil then
		enemies={}
	end
	if kind=="grabguy" then
		new_grabguy(offset)
	elseif kind=="knifeguy" then
		new_knifeguy(offset)
	elseif kind=="stickguy" then
		new_stickguy()
	elseif kind=="snake" then
		new_snake(offset)
	elseif kind=="ball" then
		new_ball(offset)
	elseif kind=="dragon" then
		new_dragon(offset)
	elseif kind=="boomerangguy" then
		new_boomerangguy()
	end
end

-- grabguy
function new_grabguy(offset)
	
	if enemies==nil then
		enemies={}
	end
	
	local grabguy={
		kind="grabguy",
		y=baseline,
		state="walking",
		anim=0,
		value=100,
		body={
			x=0,
			y=0,
			width=8,
			height=16
		},
		health=1,
		speed=1.25,
		direction=right,
		scored=false
	}
	
	if offset==nil then
		offset=0
	end
	local n=flr(rnd(2))
	if n==0 then
		grabguy.x=camera_x-16-offset
	else
		grabguy.x=camera_x+127+offset
	end
	
	grabguy.update=function(self)
		self.body.x=grabguy.x+4
		self.body.y=grabguy.y
		if self.health<=0 then
			self.state="dead"
		end
		if self.state=="walking" then	
			if ticks%3==0 then
				self.anim+=1
				if self.anim>1 then
					self.anim=0
				end
			end
			if self.x<player.x then
				self.direction=right
				self.x+=self.speed
			elseif self.x>player.x then
				self.direction=left
				self.x-=self.speed
			end
			if collision(self.body,player.body) then
				self.state="grabbing"
				add(player.grabbers,self)
				player.grabbed+=3
			end
		elseif self.state=="dead" or
				self.state=="shook" then
			self.x+=self.direction*-1
			self.y+=gravity
			if self.y>camera_y+127 then
				del(enemies,self)
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
		elseif grabguy.state=="dead" or
				grabguy.state=="shook" then
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
function new_knifeguy(offset)
	
	if enemies==nil then
		enemies={}
	end
	
	local knifeguy={
		y=baseline,
		health=2,
		state="walking",
		value=200,
		scored=false,
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
	
	if offset==nil then
		offset=0
	end
	local n=flr(rnd(2))
	if n==0 then
		knifeguy.x=camera_x-16-offset
	else
		knifeguy.x=camera_x+127+offset
	end
	
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
					y+=10
					self.attack_height=up
				else
					self.attack_height=down
				end
				new_knife(self.x,y,self.direction*2)
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
		pal(1,1)
		local sprite=128
		if self.state=="walking" then
			sprite=128+self.anim*2
		elseif self.state=="throwing" then
			if self.throwing>=self.throw_time/2 then
				sprite=132
			else
				sprite=134
			end
			-- opposite (it changed)
			if self.attack_height==up then
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
		if sprite==132 or sprite==136 then
			local x,y
			if self.direction==right then
				x=self.x-3
			else
				x=self.x+10
			end	
			if self.attack_height==up then
				y=self.y-3
			else
				y=self.y+5
			end
			spr(98,x,y,1,1,not flip_x)
		end
		spr(sprite,self.x,self.y,2,2,flip_x)
	end

	add(enemies,knifeguy)

end

-- stick guy
function new_stickguy(offset)

	if enemies==nil then
		enemies={}
	end

	local stickguy={
		kind="stickguy",
		y=baseline,
		body={
			x=0,
			y=0,
			width=8,
			height=16,
		},
		hitbox={
			x=0,
			y=0,
			width=4,
			height=4
		},
		state="waiting",
		anim=0,
		chain=0,
		swinging=0,
		speed=1.5,
		cooldown=0,
		health=boss_health,
	}
	
	if is_odd(current_level) then
		stickguy.x=min_x+16
		stickguy.direction=right
	else
		stickguy.x=max_x-32
		stickguy.direction=left
	end
	
	stickguy.update=function(self)
		if self.health<=0 then
			self.state="dead"
		end
		self.hitbox.x=self.x
		self.hitbox.y=self.y
		if self.direction==left then
			self.hitbox.x=self.x-2
		else
			self.hitbox.x=self.x+14
		end
		if self.position==down then
			self.hitbox.y=self.y+8		
		end
		if self.state=="walking" then
			if ticks%3==0 then
				self.anim+=1
				if self.anim>1 then
					self.anim=0
				end
			end
			if self.cooldown>0 then
				self.x+=self.speed*self.direction*-1
				self.cooldown-=1
			else
				local target
				local window=2
				if self.x<player.x then
					target=player.x-8
				else
					target=player.x+8
				end
				if self.x<target-window then
					self.x+=self.speed
					self.direction=right
				elseif self.x>target+window then
					self.x-=self.speed
					self.direction=left
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
		elseif self.state=="dead" then
			self.x+=self.direction*-1
			self.y+=gravity
			if self.y>camera_y+127 then
				del(enemies,self)
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
		local flip_x
		if self.direction==right then
			flip_x=false
		else
			flip_x=true
		end
		spr(sprite,self.x,self.y,2,2,flip_x)

		if self.swinging>0 and self.swinging<5 then
			if self.direction==right then
				if self.position==up then
					line(self.x+15,self.y+2,self.x+19,self.y-2,0)
				else
					line(self.x+15,self.y+9,self.x+20,self.y+9,0)				
				end
			else
				if self.position==up then
					line(self.x,self.y+2,self.x-4,self.y-2,0)             
				else
					line(self.x,self.y+9,self.x-7,self.y+9,0)				
				end
			end
		end
	end
	
	add(enemies,stickguy)
	
end

-- ball
function new_ball(x)
	if enemies==nil then
		enemies={}
	end
	local ball={
		kind="ball",
		y=0,
		state="falling",
		countdown=50,
		anim=0,
		body={
			x=0,
			y=0,
			width=8,
			height=8,
		},
		health=1
	}
	ball.x=flr(rnd(64))+camera_x+32
	ball.update=function(self)
		if self.health<=0 then
			new_effect("break",self.x,self.y)
			del(enemies,self)
		end
		local dest_y=camera_y+48
		if ticks%3==0 then
			self.anim+=1
			if self.anim>1 then
				self.anim=0
			end
		end
		if self.state=="falling" then
			self.y+=gravity
			if self.y>dest_y then
				self.y=dest_y
				self.state="countdown"
				self.start_x=ball.x
				self.start_y=ball.y
			end
		elseif self.state=="countdown" then
			if self.anim==0 then
				self.x=ball.start_x
				self.y=ball.start_y
			else
				local x=flr(rnd(2))-1
				local y=flr(rnd(2))-1
				self.x+=x
				self.y+=y
			end
			self.countdown-=1
			if self.countdown<1 then
				new_effect("break",self.x,self.y)
				local shards={
					{xs=-2,ys=-2},
					{xs=2, ys=-2},
					{xs=-2,ys=2},
					{xs=2, ys=2}
				}
				for shard in all(shards) do
					new_shard(self.x,self.y,shard.xs,shard.ys)
				end
				del(enemies,self)
			end
		end
		self.body.x=ball.x
		self.body.y=ball.y
	end
	ball.draw=function(self)
		sprite=124
		spr(124,self.x,self.y,1,1)
	end
	add(enemies,ball)
end

-- dragon
function new_dragon(x)

	if enemies==nil then
		enemies={}
	end
	
	local dragon={
		kind="dragon",
		x=x,
		y=camera_y-8,
		anim=0,
		state="falling",
		health=1,
		idle_count=10,
		breath_count=10,
		body={
			x=0,
			y=0,
			width=8,
			height=16
		}
	}
	dragon.x=flr(rnd(64))+camera_x+32
	dragon.update=function(self)
		self.body.x=self.x
		self.body.y=self.y
		local bottom=baseline
		if self.state=="falling" then
			self.body.y=self.y+8
			self.y+=gravity
			if self.y>bottom then
				self.y=bottom
				self.state="appearing"
			end
		elseif self.state=="appearing" then
			if ticks%3==0 then
				self.anim+=1
				if self.anim>5 then
					self.anim=5
					self.state="idle"
				end
			end
		elseif self.state=="idle" then
			if self.idle_count<1 then
				self.state="breathing"
				local x
				local xs
				if self.x<player.x then
					x=self.x+13
					xs=1
				else
					x=self.x-16
					xs=-1
				end
				new_fire(x,self.y,xs)
			end
			self.idle_count-=1
		elseif self.state=="breathing" then
			if self.breath_count<1 then
				self.state="disappearing"
			end
			self.breath_count-=1			
		elseif self.state=="disappearing" then
			if ticks%3==0 then
				self.anim-=1
				if self.anim<1 then
					del(enemies,self)
				end
			end
		end
		if self.health<=0 then
			if self.state=="falling" or
					self.state=="appearing" then
				new_effect("break",self.x,self.y)
				del(enemies,self)
			elseif self.state=="idle" then
				self.anim=5
				self.state="disappearing"
			end
		end
	end
	
	dragon.draw=function(self)
		local sprite=72
		if self.state=="falling" then
			sprite=72
		elseif self.state=="appearing" or
				self.state=="disappearing" then
			if self.anim==0 then
				sprite=72
			elseif self.anim==1 then
				sprite=73
			elseif self.anim==2 then
				sprite=74
			elseif self.anim==3 then
				sprite=75
			elseif self.anim==4 then
				sprite=76
			else
				sprite=77
			end
		elseif self.state=="idle" then
			sprite=77
		elseif self.state=="breathing" then
			sprite=77
		end
		local flip_x
		if self.x<player.x then
			flip_x=false
		else
			flip_x=true
		end
		if test_mode and show_enemy_bodies then
			draw_box(self.body,10)
		end
		local x=self.x
		local y=self.y
		spr(sprite,x,y,1,2,flip_x)
	end
	
	add(enemies,dragon)

end

-- snake
function new_snake(offset)
	
	if enemies==nil then
		enemies={}
	end
	
	local snake={
		kind="snake",
		y=camera_y-8,
		speed=2,
		anim=0,
		health=1,
		breaking=0,
		state="falling",
		body={
			x=x,
			y=camera_y-8,
			width=8,
			height=8,
		}
	}

	snake.x=flr(rnd(64))+camera_x+32
	
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
	
-- knife guy
function new_boomerangguy(offset)
	
	if enemies==nil then
		enemies={}
	end
	
	local boomerangguy={
		x=x,
		y=baseline,
		health=boss_health,
		state="waiting",
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
	
	if is_odd(current_level) then
		boomerangguy.x=min_x+16
		boomerangguy.direction=right
	else
		boomerangguy.x=max_x-32
		boomerangguy.direction=left
	end
	
	boomerangguy.update=function(self)
		if self.health<=0 then
			self.state="dead"
		end
		self.body.x=self.x+4
		self.body.y=self.y
		if self.state=="walking" then
			local target
			local window=4
			if self.x<player.x then
				self.direction=right
				target=player.x-32
			else
				self.direction=left
				target=player.x+47
			end
			if ticks%3==0 then
				self.anim+=1
				if self.anim>1 then
					self.anim=0
				end
			end
			if self.x<target-window then
				self.direction=right
				self.state="walking"
				self.x+=self.speed
			elseif self.x>target+window then
				self.direction=left
				self.state="walking"
				self.x-=self.speed
			else
				self.state="throwing"
				self.throwing=self.throw_time
				self.cooldown=50
			end
			-- stay on screen
			if self.x>max_x-16 then
				self.x=max_x-16
				self.state="throwing"
			elseif self.x<min_x then
				self.x=min_x
				self.state="throwing"
			end
		elseif self.state=="throwing" then
			-- time of release
			if self.throwing==self.throw_time/2 then
				local y=self.y-2
				local attack_height=self.attack_height
				if self.attack_height==down then
					y+=10
					self.attack_height=up
				else
					self.attack_height=down
				end
				new_boomerang(self.x,y,attack_height,self.direction,self)
				--new_knife(self.x,y,self.direction*2)
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
	
	boomerangguy.draw=function(self)
		pal(1,3)
		local sprite=128
		if self.state=="walking" then
			sprite=128+self.anim*2
		elseif self.state=="throwing" then
			if self.throwing>=self.throw_time/2 then
				sprite=132
			else
				sprite=134
			end
			-- opposite (it changed)
			if self.attack_height==up then
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
		if sprite==132 or sprite==136 then
			local x,y,sprite
			if self.direction==right then
				x=self.x-2
			else
				x=self.x+10
			end	
			if self.attack_height==up then
				y=self.y-2
				sprite=71
			else
				sprite=68
				y=self.y+5
			end
			spr(sprite,x,y,1,1,not flip_x)
		end
		spr(sprite,self.x,self.y,2,2,flip_x)
	end

	add(enemies,boomerangguy)

end


-- ----------------------------
-- player
-- ----------------------------

function new_player()

	player={
		score=0,
		health=100,
		y=baseline,
		grabbers={},
		grabbed=0,
		jumping=0,
		kicking=0,
		punching=0,
		hurt=0,
		speed=1,
		w_index=0,
		state="normal",
		old_input={
			x=0,
			y=0,
			k=false,
			p=false
		},
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
		}
	}

	if is_odd(current_level) then
		player.x=max_x-16
		player.direction=left
	else
		player.x=0
		player.direction=right
	end
	
	player.init=function(self,direction)
		self.direction=direction
		if direction==left then
			self.x=max_x-16
		else
			self.x=0
		end
		self.score=0
		self.health=100
		self.y=baseline
		self.grabbed=0
		self.jumping=0
		self.kicking=0
		self.punching=0
		self.hurt=0
		self.w_index=0
		self.state="normal"
	end
	
	player.update_complete=function(self)
		self.stepping=false
		if (is_even(current_level) and self.x<max_x) or
				(is_odd(current_level) and self.x>min_x-3) then
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
	
	player.update_cutscene=function(self)
		self.state="normal"
		self.walking=true
		if ticks%3==0 then
			self.w_index+=1
			if self.w_index>1 then
				self.w_index=0
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
		if ticks%3==0 then
			self.w_index+=1
			if self.w_index>1 then
				self.w_index=0
			end
		end
		self.walking=true
		self.x+=player.speed*player.direction
	end
	
	player.update=function(self)
		
		-- always apply gravity
		self.y+=gravity
		if self.y>baseline then
			self.y=baseline
		end
		
		-- always update body
		self.body.x=self.x+4
		self.body.y=self.y
		if self.position==down then
			self.body.y=self.y+8
		end
		
		-- always update hitbox
		--update_hitbox(self)
			
		self.hitbox.x=self.x
		self.hitbox.y=self.y
		self.hitbox.width=4
		self.hitbox.height=4
		if self.direction==left then
			self.hitbox.x=self.x-2
		else
			self.hitbox.x=self.x+14
		end
		if self.position==down then
			self.hitbox.y=self.y+8		
		end
		if (self.jumping>0 and self.kicking>0) then
			self.hitbox.height=16
		end

		-- update striking
	
		if self.kicking>0 then
			self.kicking-=1
		end

		if self.punching>0 then
			self.punching-=1
		end
				
		-- update hurt
		if self.hurt>0 then
			self.hurt-=1
		end
		
		if self.grabbed>0 then
			player.health-=1
		end
		
		-- if no health left then die
		if self.health<=0 then
			if test_mode==false then
				change_mode("death")
			end
		end
		
		-- if we're at end of level
		if (is_odd(current_level) and self.x<=min_x) or
				(is_even(current_level) and self.x+15>=max_x) then
			change_mode("complete")
		end
		--update_hitbox(self)

		-- get input
		local input=get_input()
		
		if #self.grabbers==0 then
			if input.k and
					self.old_input.k==false and
					self.kicking<strike_duration*.75 then
				self.kicking=strike_duration
			end
			if input.p and
					self.old_input.p==false and
					self.punching<strike_duration*.75 then
				self.punching=strike_duration
			end
		end
		
		if self.state=="normal" then
			if ticks%3==0 then
				self.w_index+=1
				if self.w_index>1 then
					self.w_index=0
				end
			end
			if input.x~=0 then
				self.direction=input.x
				if #self.grabbers>0 then
					if self.old_input.x~=input.x then
						self.grabbed-=1
					end
					if self.grabbed<=0 then
						for enemy in all(self.grabbers) do
							enemy.state="shook"
							del(self.grabbers,enemy)
						end
						self.grabbed=0
					end
				elseif self.kicking==0 and
					 self.punching==0 and
					 self.position==up then
				 self.x+=input.x*self.speed
				 self.walking=true
				else
					self.walking=false
				end
			else
				self.walking=false
			end
			if input.y==up and
					self.kicking==0 and
					self.punching==0 and
					self.grabbed==0 then
				self.state="jumping"
				self.jumping=jump_max
				self.jump_dir=input.x
			elseif input.y==down then
				self.position=down
			else
				self.position=up
			end
		
		elseif self.state=="jumping" then
			-- update jumping
			if self.jumping>0 then
				self.jumping-=1
				self.y-=gravity*2
				self.x+=self.jump_dir
			else
				self.state="falling"
			end
			
		elseif self.state=="falling" then
			self.x+=self.jump_dir
			if self.y>=baseline then
				self.state="normal"
			end					
		end
				
		self.old_input=input
			
	end
	
	-- draw player
	player.draw=function(self)
		local sprite
		if self.state=="normal" then
			sprite=0
			if self.position==down then
				sprite=14
				if player.kicking>0 then
					sprite=32
					if is_climax(player.kicking) then
   			sprite=42
	   	end
 	 	elseif player.punching>0 then
  			sprite=32
	  		if is_climax(player.punching) then
 	 			sprite=34
	  		end
 	 	end
			elseif self.walking then
				sprite=self.w_index*2
 	 else
				if player.kicking>0 then
					sprite=10
					if is_climax(player.kicking) then
						sprite=8
					end
				elseif player.punching>0 then
					sprite=10
					if is_climax(player.punching) then
						sprite=12
					end
				end
			end
			
		elseif self.state=="jumping" or
				self.state=="falling" then
			if player.kicking>0 then
				sprite=44
				if is_climax(player.kicking) then
					sprite=38
				end
			elseif player.punching>0 then
				sprite=44
				if is_climax(player.punching) then
					sprite=40
				end	
			else
				sprite=6
				if self.state=="falling" then
					sprite=44					
				end
			end
		end
		
		local flip_x=false
		if self.direction==left then
			flip_x=true
		end
		
		if test_mode and show_player_body then
			draw_box(self.body,10)
		end	
		
		if test_mode and show_player_hitbox then
			draw_box(self.hitbox,10)
		end		

		spr(sprite,self.x,self.y,2,2,flip_x)

	end

end

function init_player()
	new_player()
end

-- get game input
function get_input()

	local input={
		x=0,
		y=0,
		k=false,
		p=false
	}
	
	if btn(⬅️) and btn(➡️)==false then
		input.x=left
	elseif btn(➡️) and btn(⬅️)==false then
		input.x=right
	end	
	
	if btn(⬆️) and btn(⬇️)==false then
		input.y=up
	elseif btn(⬇️) and btn(⬆️)==false then
		input.y=down
	end
	
	if btn(4) then
		input.k=true
	end
	
	if btn(5) then
		input.p=true
	end
	
	return input
	
end

-- ----------------------------
-- projectiles
-- ----------------------------

function new_boomerang(x,y,pos,dr,th)
	if projectiles==nil then
		projectiles={}
	end
	local boomerang={
		kind="boomerang",
		x=x,
		y=y,
		thrower=th,
		position=pos,
		direction=dr,
		speed=2,
		state="throw",
		rotation=0,
		body={
			x=0,
			y=0,
			width=8,
			height=8
		}
	}
	boomerang.update=function(self)
		self.body.x=self.x
		self.body.y=self.y
		self.rotation+=1
		if self.rotation>3 then
			self.rotation=0
		end
		if self.state=="throw" then
			self.x+=self.direction*self.speed
			if (self.direction==left and self.x<=camera_x+16) or
					(self.direction==right and self.x>camera_x+111) then
				if self.position==up then
					self.y+=8
				else
					self.y-=8
				end	
				self.state="return"
			end
		elseif self.state=="return" then
			self.x-=self.direction*self.speed
			if (self.direction==left and self.x>=self.thrower.x) or
					(self.direction==right and self.x<=self.thrower.x+15) then
				del(projectiles,self)
			end			
		end				
	end
	boomerang.draw=function(self)
		local flip_x
		if self.direction<0 then
			flip_x=true
		else
			flip_x=false
		end
		spr(68+self.rotation,self.x,self.y,1,1,flip_x)
	end
	add(projectiles,boomerang)
end

function new_fire(x,y,xs)
	if projectiles==nil then
		projectils={}
	end
	local fire={
		x=x,
		y=y,
		xs=xs,
		count=10,
		body={
			x=x,
			y=y,
			width=16,
			height=8
		}
	}
	fire.update=function(self)
		self.x+=self.xs
		self.body.x=self.x
		if self.count<1 then
			del(projectiles,self)
		end				
		self.count-=1
	end
	fire.draw=function(self)
		spr(108,self.x,self.y,2,1,flip_x)
	end
	add(projectiles,fire)
end

function new_knife(x,y,xs)
	if projectiles==nil then
		projectiles={}
	end
	local knife={
		x=x,
		y=y,
		xs=xs,
		body={
			x=x,
			y=y,
			width=8,
			height=8
		}
	}
	knife.update=function(self)
		self.x+=self.xs
		self.body.x=self.x
		if (self.xs<0 and self.x<camera_x-8) or
				(self.xs>0 and self.x>camera_x+127) then
			del(projectiles,self)
		end
	end
	knife.draw=function(self)
		local flip_x
		if self.xs>0 then
			flip_x=false
		else
			flip_x=true
		end
		spr(98,self.x,self.y,1,1,flip_x)
	end
	add(projectiles,knife)
end

function new_shard(x,y,xs,ys)
	if projectiles==nil then
		projectiles={}
	end
	local shard={
		x=x,
		y=y,
		xs=xs,
		ys=ys,
		body={
			x=x,
			y=y,
			width=4,
			height=4,
		}
	}
	shard.update=function(self)
		self.x+=self.xs
		self.y+=self.ys
		self.body.x=self.x
		self.body.y=self.y
		if self.x<camera_x-8 or
				self.x>camera_x+127 or
				self.y<camera_y-8 or
				self.y>camera_y+127 then
			del(projectiles,self)	
		end			
	end
	shard.draw=function(self)
		local box={
			x=self.x,
			y=self.y,
			width=2,
			height=2
		}
		draw_box(box,7)
	end
	add(projectiles,shard)
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

function new_score(x,y,n)
	if scores==nil then
		scores={}
	end
	local score={
		x=x,
		y=y-8,
		n=n,
		count=10
	}
	score.update=function(self)
		self.count-=1
		if self.count<1 then
 		del(scores,self)
 	end
	end
	score.draw=function(self)
 	print(self.n,self.x+1,self.y+1,0)
		print(self.n,self.x,self.y,7)
	end
	add(scores,score)
end

function draw_scores()
 for score in all(scores) do
		score:draw()
 end
end

function update_scores()
	for score in all(scores) do
		score:update()
	end
end

-- ----------------------------
-- game modes
-- ----------------------------

-- complete level program

function mode_complete_init()
	if is_odd(current_level) then
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
		player:update_complete()
	end
	if complete_timer>120 then
		change_mode("tally")
	end
	complete_timer+=1
end

function mode_complete_draw()
	cls(12)
	draw_level()
	player:draw()
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
	player:update_cutscene()
	player:draw()
	rectfill(0,104,127,127,0)
end

-- death program

function mode_death_init()
	music(-1)
end

function mode_death_update()
	player:update_death()
end

function mode_death_draw()
	cls(12)
	draw_level()
	draw_projectiles()
	player:draw()
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
	player:update_intro()
	if intro_timer<0 then
		change_mode("start")
	end
end

function mode_intro_draw()
	cls(12)
	draw_level()
	player:draw()
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
	spr(77,9,68,1,2)
	spr(77,110,68,1,2,true)
end

-- play (main) program

function process_level()
	local level=levels[current_level]
	new_enemy(level.boss)
	local boss=enemies[#enemies]
	while game_mode=="play" do
		local sequence=level.sequence
		for row in all(sequence) do
			for i,en in ipairs(row) do
				local offset=i*level.offset
				if (is_odd(current_level) and player.x<max_x*0.25) or
						(is_even(current_level) and player.x>max_x*0.75) then
					boss.state="walking"
				else
					new_enemy(en,offset)
				end
			end
			yield()
		end
	end
end

function mode_play_init()
	music(0)
	co_proc_lev=cocreate(process_level)
end

function mode_play_update()
	if test_mode then
		test_input()
	end
	--player_input()
	local level=levels[current_level]
	--debug(costatus(co_proc_lev))
	if ticks%level.delay==0 then
		coresume(co_proc_lev)
	end
	update_effects()
	update_enemies()
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
	player:draw()
	draw_enemies()
	draw_effects()
	draw_scores()
	draw_osd()
end

-- start program

function mode_start_init()
	level_timer=2000
	if is_odd(current_level) then
		player:init(left)
	else
		player:init(right)
	end
	update_camera()
	sfx(8)
end

function mode_start_update()
	--update_player()
	player:update_start()
	if (player.direction==left and player.x<=max_x-64) or
			(player.direction==right and player.x>=64) then
		change_mode("play")
	end
end

function mode_start_draw()
	cls(12)
	draw_level()
	player:draw()
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
cccccc09d9cccccccccccc09d9cccccccccccc09d9ccccccccccc0999cccccccccccc09d9ccccccccccccc0999cccccccccccccc0999cccccccccccccccccccc
cccccc9999cccccccccccc9999cccccccccccc9999ccccccccccc09d9ccccccccccccc999ccccccccccccc09d9cccccccccccccc09d9cccccccccccccccccccc
cccccc799ccccccccccccc799ccccccccccccc799cccccccccccc0999cc9ccccccccc799ccccc700ccccccc999cc9cccccccccccc999ccccccccccc0000ccccc
ccccc00770ccccccccccc70077ccccccccccc00770ccccccccccc7777cc9cccccccc770970cc7790cccccc00779c9ccccccccccc07700999cccccc0999cccccc
cccc000077ccccccccccc00077cccccccccc000077cccccccccc00797099ccccccc0007007077790ccccc70009909cccccccccc0770009c9cccccc09d9cccccc
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
cccccccccccccccccccccccccccccccccccccc0095cccccccccccc09d9cccccccccccccc09d9ccccccccccccccccccccccccc09d9ccccccccc0ccccccccccccc
ccccccccccccccccccccccccc0000ccccccccc0999cccccccccccc9999ccccccccccccccc999ccccccccccccccccccccccccc9999cccccccc099ccccc99ccccc
ccccccc0000ccccccccccccc0999cccccccccc799ccccccccccccc799cccccc0cccccccc07700999cccccc0000ccccccccccc799ccccccccc0999cccc99ccccc
cccccc0999cccccccccccccc09d9ccccccccc00770ccccccccccc70777cccc90ccccccc0770009c9ccccc0999ccccccccccc70777cccccccc0099c0099cccccc
cccccc09d9ccccccccccccccc999cccccccc0007709cccccccccc007970cc790ccccccc07700ccccccccc09d9ccccccccccc00797ccccccccc0777709ccccccc
ccccccc999cc9ccccccccccc07700999cccc90077799ccccccccc0099887777ccccccccc7777cccccccccc999ccccccccccc009988cccccccc000777cccccccc
cccccc00779c9cccccccccc0770009c9ccc990888cc99cccccccc099887877ccccccccc8888cccccccccc00790cccccccccc0998877ccccccc00077877cccccc
ccccc70009909cccccccccc07700ccccccc9cc7878c99ccccccccc9877779cccccccccc77777cccccccc0077770cccccccccc9877877cccccc007787777ccccc
ccccc70999099ccccccccccc7777ccccccc99c777cccccccccccccc7777cc9cccccccc777777cccccccc0077770ccccccccccc777777cccccc990877767ccccc
cccccc889987ccccccccccc8888cccccccccccc777cccccccccccccc777ccccccccccc777099cccccccc9958899ccccccccccc777099ccccccc99977077ccccc
cccccc7777787ccccccccc7777787cccccccccc777cccccccccccc7777ccccccccccc7777c000cccccccc9987987ccccccccc7777c000ccccccc99770977cccc
cccc97777c777ccccccc97777c777ccccccccc097cccccccccccc097cccccccccccc0977cccccccccccc7797777777cccccc0977cccccccccccccccc09777ccc
ccc09777ccc99cccccc09777ccc99cccccccccc09cccccccccccc09ccccccccccccc09cccccccccccccc997cccc77990cccc09cccccccccccccccccc0c7099cc
ccc00cccccc000ccccc00cccccc000cccccccccc00ccccccccccc0cccccccccccccc0cccccccccccccc000ccccccc000cccc0cccccccccccccccccccccc0000c
ccccccccbbbbbb368888888888888888cccc6cccccc6ccccccccccccccccccccccccccccccccccccccccccccccc77ccca3333c38a3333c38cccccccccccccccc
ccccccccbbbbb36baaa8aaaa8a8aaaaacccc61cccc16cccccccccccccccccccccccccccccccccccccccccccccc7777cc3388383333883833cccccccccccccccc
ccccccccbbbb36bbccc8a88a8a8a88a8cccc61cccc16cccccc11111cc11111ccccccccccccccccccccccccccc7d77d7c873333c7833333c7cccccccccccccccc
ccccccccbbb36bbbccc8a8888a8888a8cccc61cccc16cccccc166666666661ccccccccccccccccccccccccccc777777cc83ac7ccc83ac7cccccccccccccccccc
ccccccccbb36bbbbccc8aaaa8a8aaaa8666661cccc166666cc16cccccccc61cccccccccccccccccccccccccccc7777cccc3aac7ccc3aaccccccccccccccccccc
ccccccccb36bbbbbccc888888a888888c11111cccc11111ccc16cccccccc61ccccccccccccccccccc7d77d7cc7d77d7cc783b797cc83bacccccccccccccccccc
cccccccc33333333cccccccc8a8ccccccccccccccccccccccc16cccccccc61cccccccccccccccccc77777777777777777973bb7cccc3bbaccccccccccccccccc
cccccccc00000000cccccccc8a8cccccccccccccccccccccccc6cccccccc6ccccccccccccccccccc7777777777777777c7c83bbaccc83bbacccccccccccccccc
ffffffff7ccccccccccccccc8a8cccccccccccccccccccccccccccccccccccccccffffccccccccccd777777dd777777d8ccc3bba8ccc3bbacccccccccccccccc
4444444467cccccccccccccc8a8ccccccccccccccccccccccccccccccccccccccbffff8ccccccccccdd77ddccdd77ddc8cc87bb78cc83bbacccccccccccccccc
ffffffffc67cccccaaaaaaaaaaaaaaaaccccccccccccccccccccccccccccccccfbbff88fcc7777cccc7777cccc7777cca8c797baa8cc3bbacccccccccccccccc
ffffffff44ffffff8888888888888888ccccccccccccccccccccccccccccccccffbb88ffc777777cc777777cc777777ca3c87baca3c83baccccccccccccccccc
44444444ccc555ccaaaaaaaaaaaaaaaaccccccccccccccccccccccccccccccccfff88fff7777777777777777777777778a3c3bac8a3c3baccccccccccccccccc
ffffffffcccc67ccccccccccccccccccccccccccccccccccccccccccccccccccff88bbff77d77d7777d77d7777d77d77cca3ba7ccca3bacccccccccccccccccc
ffffffffccccc67cccccccccccccccccccccccccccccccccccccccccccccccccc88ffbbcc77dd77cc77dd77cc77dd77cc7caa797cccaaccccccccccccccccccc
ffffffffcccccc67ccccccccccccccccccccccccccccccccccccccccccccccccccffffcccc7777cccc7777cccc7777cccccccc7ccccccccccccccccccccccccc
4444444444444444cccccccc88888888ccccccc4444cccccccccccc4444cccccccccccc4444cccccccccccccccccccccccccc8cc8cc8c8cccccaaccccccccccc
8888888888888888cccccccca8aaaaaacccccc4999cccccccccccc4999cccccccccccc4999ccccccccccccccccccccccccc88aa8acaa8aaccca33acccccccccc
8aaaaaa88aaaaaa8cc1ccccca8cccccccccccc4959cccccccccccc4959cccccccccccc4959cccccccc4cccccccccccccc88aa7777a77a777ccbaabccccccc8cc
8a8888a88a8888a844177777a8cccccccccccc9999cccccccccccc9999cccccccccccc9999ccccccc499ccccc99ccccc8a7777777777778cca3bb3acbcc8cccb
8a8aaaa88aaaa8a84417777ca8cccccccccccc299ccccccccccccc299ccccccccccccc299cccccccc4999cccc99cccccc88aa7777a77a777cba33abcc8cccc8c
8a888888888888a8cc1ccccc88ccccccccccc2f222cccccccccccff22fccccccccccccff22ccccccc4499cffffccccccccc88aa8acaa8aacc3baab3ccb3cc3bc
8aaaaaaaaaaaaaa8cccccccccccccccccccccfff22ccccccccccfff222fcccccccccccfff2c99ccccc42222ffcccccccccccc8cc8cc8c8cccc3bb3cc3c8338c3
8888888888888888cccccccccccccccccccccfff2299ccccccccff2222fccccccccccccffff99cccccff2222ccccccccccccccccccccccccccc33cccc3b88b3c
000000000022220088888888ccccccccccccccf99299ccccccccff2222f99cccccccccc2fffcccccccff2222ffccccccccffeecccccc7ccccccccccccccccccc
00000000008e8800aaaaaaaaccccccccccccccf99fccccccccccf9922cc99ccccccccccfffccccccccff222ffffccccccfeeffecc77cc77ccccc33cccccc33cc
33333333338e8833cccccccccccccccccccccccfffccccccccccc99fffcccccccccccccfffccccccccffc2fff2fccccceeffeeffc7fcff7cccc3333cccc3333c
bbbbbbbbbb8e88bbcccccccccccccccccccccccfffccccccccccccfffffccccccccccccfffcccccccccf99ff2ffccccceeffeeff7ccccfccccc37cccccc377cc
bbbbbbbbb788887bccccccccccccccccccccccffffcccccccccccffffffcccccccccccffffcccccccccc99ff29ffccccffeeffeeccfcccc7cccc37cccccc337c
bbbbbbbbb377773bccccccccccccccccccccc29ffcccccccccccfffccfffccccccccccfffccccccccccccccc29fffcccffeeffeec7ffcf7ccc88c37ccccccc37
bbbbbbbbbb3333bbccccccccccccccccccccc29cccccccccccc299cccc99cccccccccc299ccccccccccccccc2cf299ccceffeefcc77cc77cc833837cc8888c37
bbbbbbbbbbbbbbbbccccccccccccccccccccc222ccccccccccc2222ccc222ccccccccc2222ccccccccccccccccc2222ccceeffccccc7cccc83c337cc83c3337c
ccccccc4444cccccccccccc4444ccccccccc99c4444cccccccccccc4444cccccccccccc4444ccccccccccccccccccccccccccccccccccccccccccc44444ccccc
cccccc7777cccccccccccc7777cccccccccc997777cccccccccc7c7777cccccccccccc7777cccccccccccccc4444ccccccccccccccccccccccccc44fff44cccc
ccccc749d9ccccccccccc749d9ccccccccccc749d9ccccccccccc749d9ccccccccccc749d9ccccccccccc7c7777cccccccc4ccccccccccccccccc44fdfcccccc
cccccc9999cccccccccc7c9999ccccccccccc79999cccccccccccc9999ccccccccccc79999cccccccccccc749d9ccccccc477ccccc99ccccccccc44fffcccccc
cccccc499ccccccccccccc199cccccccccccc7199ccccccccccccc199cccccccccccc7199cccccccccccccc9999ccccccc7999cccc99ccccccccc488fccccccc
ccccc77117ccccccccccc17111ccccccccccc11111ccccccccccc7711777799cccccc11111ccccccccccccc199cccccccc7199c7777cccccccccc4ff88fccccc
cccc7771117cccccccccc77711ccccccccccc17711cccccccccc7771117779ccccccc17711ccccccccccc77111ccccccc7c1111177cccccccccccc8ff8fccccc
cccc7711117cccccccccc7771199ccccccccc1777799cccccccc7711117ccccccccc71777799cccccccc7771117cccccccc771111cccccccccccccc8fffccccc
cccc771111799ccccccccc799199cccccccccc177799cccccccc771111cccccccccc91177799cccccccc77111177ccccccc77111177ccccccccccc888fcccccc
cccc79911cc99ccccccccc7997cccccccccccc1111cccccccccc79911ccccccccccc991111cccccccccc79911cc799ccccc771117777cccccccccc8888cccccc
ccccc99777ccccccccccccc777ccccccccccccc777ccccccccccc997777cccccccccccc777ccccccccccc997777c99ccccc77c777717ccccccccccc888cccccc
cccccc77777cccccccccccc777ccccccccccccc777cccccccccccc777777ccccccccccc777cccccccccccc777777cccccccc79977177ccccccccccc888cccccc
ccccc777777ccccccccccc7777cccccccccccc7777ccccccccccc777c777cccccccccc7777ccccccccccc777c777ccccccccc99771977cccccccccc8f8cccccc
cccc777cc777ccccccccc1977cccccccccccc1977ccccccccccc777ccc77ccccccccc1977ccccccccccc777ccc77ccccccccccccc19777cccccccccffccccccc
ccc199cccc99ccccccccc19cccccccccccccc19cccccccccccc199ccc199ccccccccc19cccccccccccc199ccc199ccccccccccccc1c7199cccccc8f8ffcccccc
ccc1111ccc111cccccccc111ccccccccccccc111ccccccccccc1111ccc111cccccccc111ccccccccccc1111ccc111ccccccccccccccc1111ccccc88c888ccccc
cccccccc0000cccccccccccc0000cccc000009900000cccccccccccc0000ccccccc0ccccccccccccccccccccccccccccccccccc0cccccccccccccccccccccccc
ccccccc0999cccccccccccc0999cccccccccc990999cccccccccccc0999ccccccccc0ccccccccccccccccccccccccccccccccccc0ccccccccccccccccccccccc
ccccccc0959cccccccccccc0959c0ccccccccc60959cccccccccccc0959cccccccccc0ccccccccccccccccccccccccccccc0ccccc0ccccccccccc44444cccccc
ccccccc9999cc0ccccccccc9999c0ccccccccc69999cccccccccccc9999cc99ccccccc0cc0000cccccccccccc0000ccccc099ccccc99cccccccc44fff44ccccc
ccccccc499ccc0ccccccccc499cc0ccccccccc6499ccccccccccccc499cc609cccccccc90999cccccccccccc0999cccccc0999cccc99cccccccc44fdfccccccc
cccccc66446cc0cccccccc46444c0ccccccccc44444ccccccccccc66446606ccccccccc909596ccccccccccc0959cccccc0099c6666c0ccccccc44fffccccccc
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
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001010101010101010000000000000101010101010101010100000000000001010101010100000000000000000000000001010101000000000000000000000000
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

