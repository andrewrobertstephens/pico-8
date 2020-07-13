pico-8 cartridge // http://www.pico-8.com
version 29
__lua__
-- ===================
-- kung fu
-- andrew stephens
-- june 2020
-- version 0.1
-- ===================

test_mode=false
no_enemies=true
show_enemy_bodies=true
show_enemy_hitboxes=true
show_player_body=true
show_player_hitbox=true
show_test_osd=true
skip_cutscene=true

-- constants
left=-1
right=1
up=-1
down=1
baseline=65
boss_health=15
enemy_strike_time=10
gravity=2
hit_time=2
player_hit_time=5
enemy_hit_time=5
jump_max=8
jump_force=2


strike_duration=8
strike_contact=6
strike_hold=2
ticks=0
fire_time=30
cutscene_timer=0
cutscene_flash=false
msc_bg=0
msc_intro=5
snd_strike=9
snd_hit=10
snd_snake=11
snd_dragon=12
snd_count=14
snd_boomerang=15
snd_walking=8

-- globals
anim_index=0
chunk_size=64
level_size=20
min_x=chunk_size
max_x=(level_size-1)*chunk_size

sequences={
	{
		{"grabguy","grabguy","grabguy"},
		{"grabguy","grabguy","grabguy"},
		{"knifeguy"}
	},
	{
		{"snake"},
		{"snake"},
		{"ball"},
		{"snake"},
		{"snake"},
		{"dragon"}
	},
	{
		{"grabguy","grabguy"},
		{"snake"}
	}
}

levels={
	{
		blocks="<__b11111111111111__",
		boss="stickguy"
	},
	{
		blocks="__22222222111111b__>",
		boss="boomerangguy"
	},
	{
		blocks="<__b11111113333333__",
		boss="bigguy"
	},
	{
		blocks="__hmlh_111111111b__>",
		boss="magician"
	},
	{
		blocks="<__b11111112222222__",
		boss="mrx"
	}
}

current_level=1
active_level=nil

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
	change_mode("menu")
	printh("kungfu.p8 log",logfile,true)
end

function _update()
	ticks=ticks+1
	if ticks%3==0 then
		anim_index+=1
		if anim_index>1 then
			anim_index=0
		end
	end
	if game_mode=="menu" then
		menu_mode:update()
	elseif game_mode=="start" then
		start_mode:update()
	elseif game_mode=="play" then
		play_mode:update()
	elseif game_mode=="death" then
		death_mode:update()
	elseif game_mode=="complete" then
		complete_mode:update()
	elseif game_mode=="tally" then
		tally_mode:update()
	elseif game_mode=="cutscene" then
		cutscene_mode:update()
	end
end

function _draw()
	if game_mode=="menu" then
		menu_mode:draw()
	elseif game_mode=="start" then
		start_mode:draw()
	elseif game_mode=="play" then
		play_mode:draw()
	elseif game_mode=="death" then
		death_mode:draw()
	elseif game_mode=="complete" then
		complete_mode:draw()
	elseif game_mode=="tally" then
		tally_mode:draw()
	elseif game_mode=="cutscene" then
		cutscene_mode:draw()
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
	if game_mode=="menu" then
		menu_mode:init()
	elseif game_mode=="start" then
		start_mode:init()
	elseif game_mode=="play" then
		play_mode:init()
	elseif game_mode=="death" then
		death_mode:init()
	elseif game_mode=="complete" then
		complete_mode:init()
	elseif game_mode=="tally" then
		tally_mode:init()
	elseif game_mode=="cutscene" then
		cutscene_mode:init()
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
	local rect1,rect2=parse_rect(r1),parse_rect(r2)
	return rect1.x1<rect2.x2 and
  rect1.x2>rect2.x1 and
  rect1.y1<rect2.y2 and
  rect1.y2>rect2.y1
end

-- print to log
function debug(message)
	printh(message,"kungfu")
end

-- draw a box shape
function draw_box(box,c)
	rectfill(
		box.x,
		box.y,
		box.x+box.width-1,
		box.y+box.height-1,
		c
	)
end

-- draw the osd
function draw_osd()
 function get_boss_health()
 	local boss=get_boss()
 	if boss then
 		return boss.health/boss_health
 	end
  return 0
 end
	function draw_osd_level(sx,y)
		for i=1,5 do
			local c=12
			local x=(i-1)*8+sx
			if i<current_level then
				print("█",x,y,9)
			elseif i==current_level and anim_index==0 then
				print("█",x,y,9)
			else
				print("█",x,y,12)
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
	rectfill(camera_x,camera_y,camera_x+127,camera_y+24,1)
	print('player',x,y,9)
	health_bar(x+25,y,player.health/100,9)
	print(' enemy',x,y+8,8)
	health_bar(x+25,y+8,get_boss_health(),8)	
	draw_osd_level(x+50,y)
	color(7)
	print("-"..player.lives,x+55,y+8)
	spr(246,x+48,y+7,1,1)
	print(pad(""..player.score,6),x+97,y)
	print("time:"..flr(level_timer),x+85,y+8)
	rectfill(camera_x,camera_y+105,camera_x+127,camera_y+127,1)
	if test_mode and show_test_osd then
		cursor(camera_x+2,camera_y+107)
		print("game_mode="..game_mode,7)
		print("enemies="..#enemies,7)
	end
end

-- get boss
function get_boss()
	for en in all(enemies) do
		if en.boss then
			return en
		end
	end
	return false
end

-- is number even
function is_even(n)
	return n%2==0
end

-- is number odd
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
	return 
			(r.direction==left and r.x<camera_x-r.tile_width*8) or
			(r.direction==right and r.x>camera_x+127+r.tile_width*8) or
			r.y>127
end

-- https://www.lexaloffle.com/bbs/?tid=3595
function pad(string,length)
  if (#string==length) return string
  return "0"..pad(string, length-1)
end

-- place boss at end of level
function place_boss(boss)
	boss.x=max_x-chunk_size*2
	boss.direction=left
	if is_odd(current_level) then
		boss.x=min_x+chunk_size*2
		boss.direction=right
	end	
end

-- random position (up,down)
function random_pos()
	local n=flr(rnd(2))
	if n==0 then
		return up
	end
	return down
end

-- reset palette
function reset_palette()
	for i=0,15 do
		pal(i,i)
	end
end

-- show sprite made of strings
function str_spr(str,sx,sy)
	for y,row in ipairs(str) do
		for x,col in ipairs(split(row,"")) do
			pset(sx+x-1,sy+y-1,col)
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
		'bigguy',
		'nest',
		'mrx',
	}
	local key=stat(31)
	local num=tonum(key)
	if game_mode=="play" then
		if num~=nil then
			local en=ens[num]
			new_enemy(en)
		end
		if key=="<" then
			player.x=min_x+64
		elseif key==">" then
			player.x=max_x-80
		elseif key=="a" then
			local boss=get_boss()
			if boss then
				boss.state="ready"
			end
		elseif key=="b" then
			show_enemy_bodies=not show_enemy_bodies
			show_player_body=not show_player_body
		elseif key=="e" then
			no_enemies=not no_enemies
		elseif key=="h" then
			show_enemy_hitboxes=not show_enemy_hitboxes
			show_player_hitbox=not show_player_hitbox
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
	local effect={
		kind=kind,
		x=x,
		y=y,
		countdown=3,
		done=false,
		update=function(self)
			self.countdown-=1
			if self.countdown<1 then
				del(effects,self)
			end
		end,
		draw=function(self)
			if self.kind=="enemy_hit" then
				print("✽",self.x,self.y,7)		
			elseif self.kind=="player_hit" then
				print("✽",self.x,self.y,8)
			elseif self.kind=="break" then
				spr(125,self.x,self.y)
			end
		end
	}
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
		if enemy.state=="dead" then
			if	enemy.scored==false then
				local value=enemy.value
				if player.last_strike=="jump" or
						player.last_strike=="punch" then
					value*=2
				end
				player.score+=value
				enemy.scored=true
				new_score(enemy.x,enemy.y,value)
			end
			if enemy.y>camera_y+127 then
				del(enemies,enemy)
			end
			enemy.x-=enemy.direction
			enemy.y+=gravity
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

-- hurt an enemy
function hurt_enemy(enemy,damage)
	if enemy.hit==nil or enemy.hit<1 then
		enemy.health-=damage
		new_effect("enemy_hit",player.hitbox.x-2,player.hitbox.y)
		enemy.hit=enemy_hit_time
	end
end

-- catchall function
function new_enemy(kind,offset)
	local enemy
	if kind=="grabguy" then
		enemy=new_grabguy(offset)
	elseif kind=="knifeguy" then
		enemy=new_knifeguy(offset)
	elseif kind=="stickguy" then
		enemy=new_stickguy()
	elseif kind=="snake" then
		enemy=new_snake(offset)
	elseif kind=="ball" then
		enemy=new_ball(offset)
	elseif kind=="dragon" then
		enemy=new_dragon(offset)
	elseif kind=="boomerangguy" then
		enemy=new_boomerangguy()
	elseif kind=="bigguy" then
		enemy=new_bigguy()
	elseif kind=="nest" then
		enemy=new_nest(offset)
	end
	add(enemies,enemy)
end

-------------------------------
-- magician
-------------------------------

function new_magician(offset)
	local magician={
		x=0,
		y=0,
		health=boss_health,
	}
	place_boss(magician)
	return magician
end

-------------------------------
-- nest
-------------------------------

function new_nest(offset)
	offset=offset or 0
	if player.direction==right then
		x=player.x+100+offset
	else
		x=player.x-16-offset
	end
	local nest={
		x=x,
		y=flr(rnd(32))+camera_y+32,
		state="waiting",
		countdown=0,
		body={
			x=0,
			y=0,
			width=8,
			height=8,
		},
		update=function(self)
			if state=="waiting" then
				if player.x>self.x-100 or
						player.x<self.x+100 then
					self.state="active"
				end
			elseif state=="active" then
				if countdown>0 then
					countdown-=1
				else
					new_bug(self.x,self.y)
					countdown=40
				end
			end
		end,
		draw=function(self)
			spr(251,self.x,self.y)
		end
	}
	return nest
end

-------------------------------
-- grabguy
-------------------------------

function new_grabguy(offset)
	offset=offset or 0
	local n=flr(rnd(2))
	local x
	if n==0 then
		x=camera_x-16-offset
	else
		x=camera_x+127+offset
	end
	local grabguy={
		kind="grabguy",
		y=baseline,
		x=x,
		state="walking",
		value=100,
		body={
			x=0,
			y=0,
			width=8,
			height=16
		},
		hit=0,
		health=1,
		speed=1.25,
		direction=right,
		scored=false,
		update=function(self)
			self.hit-=1
			if self.hit<1 then
				self.hit=0
			end
			self.body.x=self.x+4
			self.body.y=self.y
			if self.health<=0 then
				self.state="dead"
			end
			if self.state=="walking" then	
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
			elseif self.state=="shook" then
				self.x+=self.direction*-1
				self.y+=gravity
				if self.y>camera_y+127 then
					del(enemies,self)
				end
			end
		end,
		draw=function(grabguy)
			local sprite=100
			local flip_x
			if grabguy.state=="walking" then
				sprite=100+anim_index*2
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
	}
	return grabguy
end

-------------------------------
-- knife guy
-------------------------------

function new_knifeguy(offset)
	offset=offset or 0
	local x
	local n=flr(rnd(2))
	if n==0 then
		x=camera_x-16-offset
	else
		x=camera_x+127+offset
	end
	local knifeguy={
		x=x,
		y=baseline,
		health=2,
		hit=0,
		state="walking",
		value=400,
		scored=false,
		body={
			x=0,
			y=0,
			width=8,
			height=16,
		},
		speed=1.5,
		direction=right,
		attack_height=up,
		throw_time=20,
		cool_time=50,
		cooldown=0,
		update=function(self)
			self.hit-=1
			if self.hit<1 then
				self.hit=0
			end
			if self.health<=0 then
				self.state="dead"
			end
			self.body.x=self.x+4
			self.body.y=self.y
			local target
			local window=8
			if self.x<player.x then
				self.direction=right
				target=player.x-32
			else
				self.direction=left
				target=player.x+32
			end
			if self.state=="walking" then
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
					sfx(snd_strike)
					new_knife(self.x,y,self.direction*2)
				elseif self.throwing<1 then
					self.state="cooldown"
					self.cooldown=self.cool_time
				end
				self.throwing-=1
			elseif self.state=="cooldown" then
				if self.cooldown<1 then
					self.state="walking"
				end
				self.cooldown-=1
			end		
		end,
		draw=function(self)
			local sprite=128
			if self.state=="walking" then
				sprite=128+anim_index*2
			elseif self.state=="throwing" then
				if self.throwing>=self.throw_time/2 then
					sprite=132
				else
					sprite=134
				end
				-- opposite (it changed)
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
	}
	return knifeguy
end

-------------------------------
-- stick guy
-------------------------------

function new_stickguy(offset)
	local stickguy={
		kind="stickguy",
		x=min_x+16,
		direction=right,
		boss=true,
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
		chain=0,
		swinging=0,
		speed=1.5,
		cooldown=0,
		health=boss_health,
		hit=0,
		power=5,
		value=1000,
		scored=false,
		update=function(self)
			self.hit-=1
			if self.hit<1 then
				self.hit=0
			end
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
			if self.state=="ready" then
				self.state="walking"
			elseif self.state=="walking" then
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
						sfx(snd_strike)
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
			if collision(self.hitbox,player.body) and self.swinging==1 then
				player:hurt(self.power)
				sfx(snd_hit)
				new_effect("player_hit",self.hitbox.x,self.hitbox.y)
			end
		end,
		draw=function(self)
			local sprite=160
			if self.state=="walking" then
				sprite=160+anim_index*2
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
	}
	place_boss(stickguy)	
	return stickguy	
end

-------------------------------
-- big guy
-------------------------------

function new_bigguy(offset)
	local bigguy={
		kind="bigguy",
		x=min_x+16,
		direction=right,
		boss=true,
		y=baseline-8,
		body={
			x=0,
			y=0,
			width=8,
			height=24,
		},
		hitbox={
			x=0,
			y=0,
			width=8,
			height=8
		},
		state="waiting",
		chain=0,
		striking=0,
		speed=1,
		cooldown=0,
		health=boss_health,
		hit=0,
		power=5,
		update=function(self)
			if self.hit>0 then
				self.hit-=1
			end
			if self.health<=0 then
				self.state="dead"
			end
			self.hitbox.x=self.x
			self.hitbox.y=self.y+2
			if self.direction==left then
				self.hitbox.x=self.x-8
			else
				self.hitbox.x=self.x+8
			end
			if self.state=="ready" then
				self.state="walking"
			elseif self.state=="walking" then
				if self.cooldown>0 then
					self.x-=self.speed*self.direction
					self.cooldown-=1
				else
					local target
					local window=2
					if self.x<player.x then
						target=player.x-4
					else
						target=player.x+4
					end
					if self.x<target-window then 
						self.x+=self.speed
						self.direction=right
					elseif self.x>target+window then
						self.x-=self.speed
						self.direction=left
					else
						self.state="striking"
						self.striking=enemy_strike_time
						sfx(snd_strike)
					end			
				end
			elseif self.state=="striking" then
				if self.strike_position==down then
					self.hitbox.y=self.y+10
				end
				if self.striking<1 then
					local n=flr(rnd(2))
					if n==0 then 
						n=-1
					end

					self.strike_position=n
					self.striking=enemy_strike_time
					self.chain+=1
				else
					self.striking-=1
				end
				if self.chain>2 then
					self.chain=0
					self.cooldown=15
					self.state="walking"
				end
			end
			self.body.x=self.x
			self.body.y=self.y
			if collision(self.hitbox,player.body) and self.striking==1 then
				player:hurt(self.power)
				sfx(snd_hit)
				new_effect("player_hit",self.hitbox.x,self.hitbox.y)
			end
		end,
		draw=function(self)
			local sprite=192
			local flip_x=false
			if self.direction==left then
				flip_x=true
			end
			if self.state=="walking" then
				sprite+=anim_index*2
			elseif self.state=="striking" then
				if self.strike_position==up then
					sprite=196
				else
					sprite=200
				end
				if self.striking<enemy_strike_time/2 then
					sprite+=2
				end				
			end
			spr(sprite,self.x,self.y,2,3,flip_x)
		end
	}
	place_boss(bigguy)
	return bigguy
end

-------------------------------
-- bug
-------------------------------

function new_bug(offset)
	local direction
	local x=camera_x+64
	if x<player.x then
		direction=right
	else
		direction=left
	end
	local bug={
		x=x,
		y=camera_y+48,
		speed=2,
		health=1,
		value=200,
		direction=direction,
		body={
			x=0,
			y=0,
			width=8,
			height=8
		},
		update=function(self)
			self.x+=self.speed*self.direction	
			self.y+=0.5
			self.body.x=self.x
			self.body.y=self.y
			if self.y>camera_y+127 then
				del(enemies,self)
			end
		end,
		draw=function(self)
			local flip_x=false
			if self.direction==right then
				flip_x=true
			end
			spr(244+anim_index,self.x,self.y,1,1,flip_x)
		end
	}
	return bug
end

-------------------------------
-- ball
-------------------------------

function new_ball(x)
	local ball={
		kind="ball",
		x=flr(rnd(64))+camera_x+32,
		y=0,
		state="falling",
		countdown=50,
		power=10,
		body={
			x=0,
			y=0,
			width=8,
			height=8,
		},
		health=1,
		value=500,
		update=function(self)
			if self.health<=0 then
				new_effect("break",self.x,self.y)
				del(enemies,self)
			end
			local dest_y=camera_y+48
			if self.state=="falling" then
				self.y+=gravity
				if self.y>dest_y then
					self.y=dest_y
					self.state="countdown"
					self.start_x=self.x
					self.start_y=self.y
				end
			elseif self.state=="countdown" then
				if anim_index==0 then
					self.x=self.start_x
					self.y=self.start_y
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
			self.body.x=self.x
			self.body.y=self.y
			if collision(self.body,player.body) then
				player:hurt(self.power)
				new_effect("break",self.x,self.y)
				del(enemies,self)
			end
		end,
		draw=function(self)
			sprite=124
			spr(124,self.x,self.y,1,1)
		end
	}
	return ball
end

-------------------------------
-- dragon
-------------------------------

function new_dragon()
	local dragon={
		kind="dragon",
		x=flr(rnd(64))+camera_x+32,
		y=camera_y-8,
		anim=0,
		state="falling",
		health=1,
		idle_count=10,
		breath_count=10,
		breathing=0,
		power=5,
		body={
			x=0,
			y=0,
			width=8,
			height=16
		},
		hitbox={
			x=0,
			y=0,
			width=16,
			height=8
		},
		update=function(self)
			local bottom=baseline
			if self.x<player.x then
				self.direction=right
			else
				self.direction=left
			end
			if self.state=="falling" then
				self.body.y=self.y+8
				self.y+=gravity
				if self.y>bottom then
					self.y=bottom
					self.state="appearing"
					sfx(snd_dragon)
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
					self.breathing=20
				end
				self.idle_count-=1
			elseif self.state=="breathing" then
				if collision(self.hitbox,player.body) then
					player:hurt(self.power)
				end
				if self.breathing<1 then
					self.state="disappearing"
				end
				self.breathing-=1
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
			self.body.x=self.x
			self.body.y=self.y
			if self.direction==left then
				self.hitbox.x=self.x-16
			else
				self.hitbox.x=self.x+8
			end
			self.hitbox.y=self.y
		end,
		draw=function(self)
			local flip_x
			if self.x<player.x then
				flip_x=false
			else
				flip_x=true
			end
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
			if self.breathing>0 then
				spr(108,self.hitbox.x,self.hitbox.y,2,1,flip_x)
			end
			if test_mode and show_enemy_bodies then
				draw_box(self.body,10)
			end
			local x=self.x
			local y=self.y
			spr(sprite,x,y,1,2,flip_x)
		end
	}
	return dragon
end

-------------------------------
-- snake
-------------------------------

function new_snake(offset)
	local snake={
		kind="snake",
		x=flr(rnd(64))+camera_x+32,
		y=camera_y-8,
		speed=2,
		health=1,
		breaking=0,
		state="falling",
		power=10,
		body={
			x=x,
			y=camera_y-8,
			width=8,
			height=8,
		},
		update=function(self)
			local bottom=baseline+8
			if self.state=="falling" then
				self.y+=gravity
				if self.y>bottom then
					sfx(snd_snake)
					self.y=bottom
					self.state="breaking"
					self.breaking=5
				end
			elseif self.state=="breaking" then
				self.breaking-=1
				if self.breaking<1 then
					self.state="active"
				end
			elseif self.state=="active" then
				if self.locked_direction==nil then
					if self.x<player.x then
						self.locked_direction=right
					else
						self.locked_direction=left
					end
				end
				self.x+=self.speed*self.locked_direction
			end		
			self.body.x=self.x
			self.body.y=self.y
			self.body.width=8
			self.body.height=8
			if collision(self.body,player.body) then
				player:hurt(self.power)
				if self.state=="falling" then
					new_effect("break",self.x,self.y)
					del(enemies,self)
				end
			end
			if (self.locked_direction==right and self.x>camera_x+127) or
					(self.locked_direction==left and self.x<camera_x-16) then
				del(enemies,self)
			end
		end,
		draw=function(snake)
			local sprite
			if snake.state=="falling" then
				sprite=110
			elseif snake.state=="breaking" then
				sprite=111
			elseif snake.state=="active" then
				sprite=126+anim_index
			end
			local flip_x
			if snake.locked_direction==left then
				flip_x=true
			else
				flip_x=false
			end
			spr(sprite,snake.x,snake.y,1,1,flip_x)
		end
	}
	return snake
end
	
-------------------------------
-- boomerang guy
-------------------------------

function new_boomerangguy(offset)
	local throw_time=40
	local cooldown_time=80	
	local boomerangguy={
		boss=true,
		x=x,
		y=baseline,
		health=boss_health,
		hit=0,
		state="waiting",
		throwing=0,
		body={
			x=0,
			y=0,
			width=8,
			height=16,
		},
		speed=1.5,
		direction=right,
		attack_height=up,
		cooldown=0,
		update=function(self)
			if self.health<1 then
				self.state="dead"
			end
			if self.hit>0 then
				self.hit-=1
			end
			if self.state=="ready" then
				local target
				if player.x<self.x then
					target=player.x+48
					self.direction=left
				else
					target=player.x-48
					self.direction=right
				end
				if self.x>target then
					self.x-=1
				elseif self.x<target then
					self.x+=1
				end
				if self.x<min_x then
					self.x=min_x
				elseif self.x>max_x-16 then
					self.x=max_x-16
				end
				if self.cooldown<1 then
					self.attack_height=random_pos()
					self.state="throwing1"
					self.throwing=throw_time
				else
					self.cooldown-=1
				end
			elseif self.state=="throwing1" then
				if self.throwing<1 then
					self.attack_height=random_pos()
					self.state="throwing2"
					self.throwing=throw_time
				else
					if self.throwing==throw_time/2 then
						sfx(snd_strike)
						new_boomerang(self)
					end
					self.throwing-=1
				end		
			elseif self.state=="throwing2" then
				if self.throwing<1 then
					self.state="ready"
					self.cooldown=cooldown_time
				else
					if self.throwing==throw_time/2 then
						sfx(snd_strike)
						new_boomerang(self)
					end
					self.throwing-=1
				end
			end
			self.body.x=self.x+4
			self.body.y=self.y				
		end,
		draw=function(self)
			pal(1,8)
			local sprite=128
			local flip_x=false
			if self.state=="ready" then
				sprite=128+anim_index*2
			elseif self.state=="throwing1" or
					self.state=="throwing2" then
				if self.throwing<throw_time/2 then
					sprite=134
				else
					sprite=132
				end
				if self.attack_height==down then
					sprite+=4
				end
			end
			if self.direction==left then
				flip_x=true
			end
			spr(sprite,self.x,self.y,2,2,flip_x)
			reset_palette()
		end
	}
	place_boss(boomerangguy)
	return boomerangguy
end

-- ----------------------------
-- player
-- ----------------------------

player={
	direction=right,
	grabbed=0,
	health=100,
	hit=0,
	hurt=0,
	lives=2,
	jumping=0,
	kicking=0,
	punching=0,
	score=0,
	speed=1,
	state="normal",
	last_strike=nil,
	x=0,
	y=baseline,
	body={x=0,y=0,width=8,height=16},
	grabbers={},
	hitbox={x=0,y=0,width=4,height=4},
	old_input={x=0,y=0,k=false,p=false},
	init=function(self)
		if is_odd(current_level) then
			self.x=max_x-16
			self.direction=left
		else
			self.x=min_x
			self.direction=right
		end
		self.health=100
		self.y=baseline
		self.grabbed=0
		self.jumping=0
		self.kicking=0
		self.punching=0
		self.state="normal"
		self.hit=0
	end,
	collisions=function(self)	
		for enemy in all(enemies) do
			if collision(self.body,enemy.body) then
				self.jump_dir=0
			end
			if collision(self.hitbox,enemy.body) and
					#player.grabbers==0 then
				if is_climax(player.punching) or
						is_climax(player.kicking) then
					local strike=""
					if player.jumping>0 then
						strike="jump"
					elseif player.punching>0 then
						strike="punch"
					else
						strike="kick"
					end
					self.last_strike=strike
					hurt_enemy(enemy,1)
					if enemy.boss then
						enemy.x-=enemy.direction
					end
					sfx(-1)
					sfx(snd_hit)
				end
			end
		end
	end,	
	hurt=function(self,damage)
		if player.hit<1 then
			self.hit=player_hit_time
			self.health-=damage
		end
	end,
	update_complete=function(self)
		self.stepping=false
		if (is_even(current_level) and self.x<max_x) or
				(is_odd(current_level) and self.x>min_x-3) then
			self.walking=true
			self.stepping=false
			self.x+=complete_direction*1
		else
			self.walking=false
			self.stepping=true
		end
	end,
	update=function(self)
		if player.hit>0 then
			player.hit-=1
		end
		self.y+=gravity
		if self.y>baseline then
			self.y=baseline
		end
		if self.kicking>0 then
			self.kicking-=1
		end
		if self.punching>0 then
			self.punching-=1
		end
		if self.hit>0 then
			self.hit-=1
		end
		if self.grabbed>0 then
			player.health-=1
		end
		if self.health<=0 then
			if test_mode==false then
				change_mode("death")
			end
		end
		if (is_odd(current_level) and self.x<=min_x-2) or
				(is_even(current_level) and self.x+8>=max_x) then
			change_mode("complete")
		end
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
			if self.jumping>0 then
				self.jumping-=1
				self.y-=gravity*jump_force
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
		if self.kicking==strike_duration or self.punching==strike_duration then
			sfx(snd_strike)
		end
		self.body.x=self.x+4
		self.body.y=self.y
		if self.position==down then
			self.body.y=self.y+8
		end
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
		self:collisions()
		self.old_input=input
	end,
	draw=function(self)
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
 	 elseif self.hit>0 then
 	 	sprite=36
			elseif self.stepping then
				sprite=4+anim_index*2
			elseif self.walking then
				sprite=anim_index*2
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
		elseif self.state=="climbing" then
			sprite=2+anim_index*2		
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
}

-- get game input
function get_input()
	local input={x=0,y=0,k=false,p=false}
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
-- boomerang
-- ----------------------------

function new_boomerang(th)
	local y=th.y
	if th.attack_height==down then
		y+=8
	end
	local boomerang={
		kind="boomerang",
		x=th.x,
		y=y,
		thrower=th,
		position=th.attack_position,
		direction=th.direction,
		speed=2,
		state="throw",
		rotation=0,
		body={
			x=0,
			y=0,
			width=8,
			height=8
		},
		update=function(self)
			self.rotation+=1
			if self.rotation>3 then
				self.rotation=0
			end
			if self.state=="throw" then
				self.x+=self.direction*self.speed
				if (self.direction==left and self.x<=camera_x+16) or
						(self.direction==right and self.x>camera_x+111) then
					self.state="return"
				end
			elseif self.state=="return" then
				self.x-=self.direction*self.speed
				if (self.direction==left and self.x>=self.thrower.x) or
						(self.direction==right and self.x<=self.thrower.x+15) then
					del(projectiles,self)
				end			
			end				
			self.body.x=self.x
			self.body.y=self.y
		end,
		draw=function(self)
			local flip_x
			if self.direction<0 then
				flip_x=true
			else
				flip_x=false
			end
			spr(247+self.rotation,self.x,self.y,1,1,flip_x)
		end
	}
	add(projectiles,boomerang)
end

-------------------------------
-- knife
-------------------------------

function new_knife(x,y,xs)
	local knife={
		x=x,
		y=y,
		xs=xs,
		power=10,
		body={
			x=x,
			y=y,
			width=8,
			height=8
		},
		update=function(self)
			self.x+=self.xs
			self.body.x=self.x
			if (self.xs<0 and self.x<camera_x-8) or
					(self.xs>0 and self.x>camera_x+127) then
				del(projectiles,self)
			end
		end,
		draw=function(self)
			local flip_x
			if self.xs>0 then
				flip_x=false
			else
				flip_x=true
			end
			spr(98,self.x,self.y,1,1,flip_x)
		end
	}
	add(projectiles,knife)
end

-------------------------------
-- shard
-------------------------------

function new_shard(x,y,xs,ys)
	local shard={
		x=x,
		y=y,
		xs=xs,
		ys=ys,
		power=10,
		body={
			x=x,
			y=y,
			width=4,
			height=4,
		},
		update=function(self)
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
		end,
		draw=function(self)
			local box={
				x=self.x,
				y=self.y,
				width=2,
				height=2
			}
			draw_box(box,7)
		end
	}
	add(projectiles,shard)
end

-------------------------------
-- projectiles
-------------------------------

function update_projectiles()
	for projectile in all(projectiles) do
		projectile:update()
		if collision(projectile.body,player.body) then
			player:hurt(10)
			new_effect("player_hit",projectile.x,projectile.y)
			del(projectiles,projectile)
			if projectile.kind~=nil and 
					projectile.kind~="boomerang" then
			end
		end
	end
end

function draw_projectiles()
	for projectile in all(projectiles) do
		projectile:draw()
	end
end

-- ----------------------------
-- scores
-- ----------------------------

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

-------------------------------
-- complete level program
-------------------------------

complete_mode={
	init=function(self)
		self.x=camera_x
		self.direction=left
		self.state="normal"
		self.timer=48
		player.state="normal"
		if is_even(current_level) then
			self.direction=right
		end
	end,
	update=function(self)
		if self.state=="normal" then
			self.x+=self.direction
			update_camera(self.x)
			if self.timer<1 then
				music(-1)
				self.state="climbing"
				player.state="climbing"
			end
			self.timer-=1
		elseif self.state=="climbing" then
			if player.y<camera_y-16 then
				change_mode("tally")
			end
			if anim_index==1 then
				player.y-=2
			end
			player.x+=self.direction
		end
	end,
	draw=function(self)
		cls(12)
		draw_level()
		player:draw()
		draw_osd()
	end
}

-------------------------------
-- cut scene program
-------------------------------

cutscene_mode={
	cutscene_flash=false,
	cutscene_timer=0,
	init=function(self)
		music(msc_intro)
	end,
	update=function(self)
		if ticks%8==0 then
			cutscene_flash=not cutscene_flash
		end
		if cutscene_timer>149 then
			change_mode("start")
		else
			player.x=127-32
			player.y=baseline
			player.direction=left
			player.walking=true
		end
		cutscene_timer+=1
	end,
	draw=function(self)
		cls(12)
		--rectfill(camera_x,camera_y,camera_x+127,camera_y+24,1)
		rectfill(0,0,127,24,1)
		map(0,7,0,baseline+16,16,3)
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
		--str_spr(spr_sylvia,16,baseline)
		player:draw()
		rectfill(0,104,127,127,1)
	end
}

-------------------------------
-- death program
-------------------------------

death_mode={
	init=function(self)
		music(-1)
		for enemy in all(enemies) do
			enemy.state="idle"
		end
	end,
	update=function(self)
		player.x-=player.direction
		player.y+=gravity
		if player.y>camera_y+127 then
			change_mode("start")
		end
	end,
	draw=function(self)
		cls(12)
		draw_level()
		draw_projectiles()
		player:draw()
		draw_enemies()
		draw_scores()
		draw_effects()
		draw_osd()
	end
}

-------------------------------
-- menu program
-------------------------------

menu_mode={
	init=function(self)
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
		cursor(64-7*8/2,y+10)
		color(7)
		str_spr(title_spr,64-7*8/2,y+10)
		
		center_print("press 🅾️+❎ to start",64,y+40,7)
		spr(77,9,68,1,2)
		spr(77,110,68,1,2,true)
	end,
	update=function(self)
		if btn(4) and btn(5) then
			if test_mode and skip_cutscene then
				change_mode("start")
			else
				change_mode("cutscene")
			end
		end
	end,
	draw=function(self)
	end
}

-------------------------------
-- play (main) program
-------------------------------

-- draw the current level
function draw_level()

	function draw_block(block,x,y,first)
		local first=first or false
		if first then
			if block=="<" then
				map(0,10,x,y,8,10)
			elseif block==">" then
				map(15,10,x,y,8,10)
			else
				map(7,10,x,y,8,10)
			end		
		else
			if block=="<" then
				map(0,0,x,y,8,10)
			elseif block==">" then
				map(15,0,x,y,8,10)
			else
				map(7,0,x,y,8,10)
			end
		end
		if block=="h" then
			spr(251,x+28,y+24)
		elseif block=="m" then
			spr(251,x+28,y+36)
		elseif block=="l" then
			spr(251,x+28,y+48)
		end
	end

	local level=levels[current_level]
	local blocks=split(level.blocks,"",false)
	for i,block in ipairs(blocks) do
		local x=(i-1)*64
		draw_block(block,x,24,true)
	end

	--[[
	for i=-6,level_size/16+6 do
		local x=i*128
		if current_level==1 then
			map(0,0,x,24,16,10)
		else
			map(16,0,x,24,16,10)
		end
	end
	for i=0,5 do
		if is_even(current_level) then
			spr(81,max_x+48-i*8,33+i*8,1,1,true)
		else
			spr(81,-48+i*8,33+i*8)
		end
	end
	]]
end


function process_level()

	function do_seq_row(seq_row)
		for i,en in ipairs(seq_row) do
			new_enemy(en,i*8)
		end	
	end

	if seq_index==nil then
		seq_index=1
	end
	
	if ticks%100==0 then
		local blocks=split(active_level.blocks,"",false)
		for i,block in ipairs(blocks) do
			local startx=(i-1)*chunk_size
			local endx=startx+chunk_size-1
			if player.x>=startx and
					player.x<=endx then
				if block=="b" then
					local boss=get_boss()
					if boss and boss.state=="waiting" then
						boss.state="ready"
					end
				else
					local n=tonum(block)
					if n then
						local sequence=sequences[tonum(block)]
						local seq_row=sequence[seq_index]
						do_seq_row(seq_row)
						seq_index+=1
						if seq_index>#sequence then
							seq_index=1
						end
					end
				end
			end
		end
	end
		
end

play_mode={
	init=function(self)
		music(msc_bg)
	end,
	update=function(self)
		if test_mode then
			test_input()
		end
		process_level()
		update_effects()
		update_enemies()
		player:update()
		update_projectiles()
		update_scores()
		update_camera()
		level_timer-=0.5
	end,
	draw=function(self)
		cls(12)
		draw_level()
		draw_projectiles()
		player:draw()
		draw_enemies()
		draw_effects()
		draw_scores()
		draw_osd()
	end
}

-------------------------------
-- start program
-------------------------------

start_mode={
	init=function(self)
		active_level=levels[current_level]
		level_timer=2000
		player:init()
		effects={}
		enemies={}
		new_enemy(active_level.boss)
		projectiles={}
		update_camera()
		sfx(snd_walking)
	end,
	update=function(self)
		player.walking=true
		player.x+=player.speed*player.direction
		if (player.direction==left and player.x<=max_x-64) or
				(player.direction==right and player.x>=64) then
			change_mode("play")
		end
	end,
	draw=function(self)
		cls(12)
		draw_level()
		player:draw()
		update_camera()
		local xc=camera_x+64
		center_print("level "..current_level,xc,50,7,false)
		draw_osd()
	end
}

-------------------------------
-- tally program
-------------------------------

tally_mode={
	init=function(self)
	end,
	update=function(self)
		level_timer-=10
		player.score+=10
		sfx(snd_count)
		if level_timer<1 then
			current_level+=1
			change_mode("start")
		end
	end,
	draw=function(self)
		draw_osd()
	end
}
-->8
--[[
	todo:
		- magician
		- mr.x
		- ending
		- remove lives
		- game over
		- better boss placement?
		- stairs placement
		- climbing animation
]]
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
ccccccccbbbbbb368888888888888888ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc77ccca3333c38a3333c38cccccccccccccccc
ccccccccbbbbb36baaa8aaaa8a8aaaaacccccccccccccccccccccccccccccccccccccccccccccccccccccccccc7777cc3388383333883833cccccccccccccccc
ccccccccbbbb36bbccc8a88a8a8a88a8ccccccccc5555cccccccccccc5555cccccccccccccccccccccccccccc7d77d7c873333c7833333c7cccccccccccccccc
ccccccccbbb36bbbccc8a8888a8888a8cccccccc5999cccccccccccc5999ccccccccccccccccccccccccccccc777777cc83ac7ccc83ac7ccccccc5cccccccccc
ccccccccbb36bbbbccc8aaaa8a8aaaa8cccccccc5959cccccccccccc5959cccccccccccccccccccccccccccccc7777cccc3aac7ccc3aaccccccc599ccccccccc
ccccccccb36bbbbbccc888888a888888ccccccff9999ccccccccccff9999ccccccccccccccccccccc7d77d7cc7d77d7cc783b797cc83bacccccc5999cc99cccc
cccccccc33333333cccccccc8a8ccccccccccffff99ccccccccccffff99ccccccccccccccccccccc77777777777777777973bb7cccc3bbaccccc5599c55ccccc
cccccccc00000000cccccccc8a8cccccccccffff55fcccccccccffff55fccccccccccccccccccccc7777777777777777c7c83bbaccc83bbacccccf55ff5ccccc
ffffffff7ccccccccccccccc8a8cccccccccfff555fcccccccccfff555fcccccccffffccccccccccd777777dd777777d8ccc3bba8ccc3bbaccccff555ffccccc
4444444467cccccccccccccc8a8cccccccccff555fccccccccccff555fcccccccbffff8ccccccccccdd77ddccdd77ddc8cc87bb78cc83bbaccccfff55f7ccccc
ffffffffc67cccccaaaaaaaaaaaaaaaaccccc7557cccccccccccc7557cccccccfbbff88fcc7777cccc7777cccc7777cca8c797baa8cc3bbacccccfff559fcccc
ffffffff44ffffff8888888888888888ccccfff59cccccccccccfff59cccccccffbb88ffc777777cc777777cc777777ca3c87baca3c83bacccccccf75995cccc
44444444ccc555ccaaaaaaaaaaaaaaaaccccc5599cccccccccccc5599cccccccfff88fff7777777777777777777777778a3c3bac8a3c3bacccccccccff555ccc
ffffffffcccc67cccccccccccccccccccccc555c55ccccccccccc555ccccccccff88bbff77d77d7777d77d7777d77d77cca3ba7ccca3baccccccccccffc55ccc
ffffffffccccc67cccccccccccccccccccc955cc55ccccccccccc55cccccccccc88ffbbcc77dd77cc77dd77cc77dd77cc7caa797cccaacccccccccccccc55ccc
ffffffffcccccc67ccccccccccccccccccc999cc999cccccccccc999ccccccccccffffcccc7777cccc7777cccc7777cccccccc7cccccccccccccccccccc999cc
4444444444444444cccccccc88888888ccccccc4444cccccccccccc4444cccccccccccc4444cccccccccccccccccccccccccc8cc8cc8c8cccccaaccccccccccc
8888888888888888cccccccca8aaaaaacccccc4999cccccccccccc4999cccccccccccc4999ccccccccccccccccccccccccc88aa8acaa8aaccca33acccccccccc
8aaaaaa88aaaaaa8cc1ccccca8cccccccccccc4959cccccccccccc4959cccccccccccc4959cccccccc4cccccccccccccc88aa7777a77a777ccbaabccccccc8cc
8a8888a88a8888a844177777a8cccccccccccc9999cccccccccccc9999cccccccccccc9999ccccccc499ccccc99ccccc8a7777777777778cca3bb3acbcc8cccb
8a8aaaa88aaaa8a84417777ca8cccccccccccc299ccccccccccccc299ccccccccccccc299cccccccc4999cccc99cccccc88aa7777a77a777cba33abcc8cccc8c
8a888888888888a8cc1ccccc88ccccccccccc2f222cccccccccccff22fccccccccccccff22ccccccc4499cffffccccccccc88aa8acaa8aacc3baab3ccb3cc3bc
8aaaaaaaaaaaaaa8cccccccccccccccccccccfff22ccccccccccfff222fcccccccccccfff2c99ccccc42222ffcccccccccccc8cc8cc8c8cccc3bb3cc3c8338c3
8888888888888888cccccccccccccccccccccfff2299ccccccccff2222fccccccccccccffff99cccccff2222ccccccccccccccccccccccccccc33cccc3b88b3c
000000000022220088888888cccc6cccccccccf99299ccccccccff2222f99cccccccccc2fffcccccccff2222ffccccccccffeecccccc7ccccccccccccccccccc
00000000008e8800aaaaaaaacccc61ccccccccf99fccccccccccf9922cc99ccccccccccfffccccccccff222ffffccccccfeeffecc77cc77ccccc33cccccc33cc
33333333338e8833cccccccccccc61cccccccccfffccccccccccc99fffcccccccccccccfffccccccccffc2fff2fccccceeffeeffc7fcff7cccc3333cccc3333c
bbbbbbbbbb8e88bbcccccccccccc61cccccccccfffccccccccccccfffffccccccccccccfffcccccccccf99ff2ffccccceeffeeff7ccccfccccc37cccccc377cc
bbbbbbbbb788887bcccccccc666661ccccccccffffcccccccccccffffffcccccccccccffffcccccccccc99ff29ffccccffeeffeeccfcccc7cccc37cccccc337c
bbbbbbbbb377773bccccccccc11111ccccccc29ffcccccccccccfffccfffccccccccccfffccccccccccccccc29fffcccffeeffeec7ffcf7ccc88c37ccccccc37
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
ccccc4444cccccccccccc4444cccccccccccc4444cccccccccccc4444cccccccccccc4444ccccccccccc4444cccccccccccc4444cccccccccccccccccccccccc
cccc4999cccccccccccc4999cccccccccccc4999cccccccccccc4999cccccccccccc4999ccccccccccc4999cccccccccccc4999ccccccccccccccccccccccccc
cccc4949cccccccccccc4949cccccccccccc4949cccccccccccc4949cccccccccccc4949ccccccccccc4949cccccccccccc4999ccccccccccccccccc5555cccc
cccc9999cccccccccccc9999cccccccccccc9999cccccccccccc9999cccccccccccc9999ccccccccccc9999cccccccccccc9999cccccccccccccccc5999ccccc
cc997999cccccccccc997999cccccccccc997999ccccccccccc97999cccccccccc997999cccccccccc79999ccccccccccc97799cccccccccccccccc5959c999c
c999979cccccccccc999979cccccccccc999979cccccccccc99997979999999cc999979cccccccccc99779c9ccccccccc99997cccccccccccccccff9999599cc
c999977cccccccccc999977cccccccccc999977ccccccccc999997779999999cc999977cccccccccc9997799ccccccccc999977cccccccccccccffff9955cccc
9999777ccccccccc9999777ccccccccc9999777ccccccccc999977779999c99c9999977ccccccccc999977c9cccccccc9999777ccccccccccccffff55f5ccccc
9997777ccccccccc9997777ccccccccc9997777ccccccccc99977777cccccccc9999777ccccccccc99977799cccccccc9997777ccccccccccccfff555fcccccc
9977777ccccccccc9977777ccccccccc9977799ccccccccc9997777ccccccccc9997799ccccccccc99777799cccccccc9977777ccccccccccccff555fccccccc
9977777ccccccccc9977777ccccccccc9999999ccccccccc9997777ccccccccc9999999ccccccccc9977779ccccccccc9977777ccccccccccccc7557cccccccc
99777779cccccccc99777779cccccccc99999779ccccccccc999977cccccccccd999977dcccccccc997777ddcccccccc99777779cccccccccccfff59cccccccc
c9977799ccccccccc9977799ccccccccdddd7799ccccccccdd9997ccccccccccddddddddccccccccc9977dddddddddc0c9977ddddddc0ccccccc5599cccccccc
99ddddc9cccccccc99ddddc9ccccccccddddddc9ccccccccddddddccccccccccddddd1ddcccccccc99dddddddddddd9099ddddddddd90cccccc555c55ccccccc
cdddddcccccccccccdddddccccccccccddddddccccccccccddddddccccccccccdddd1dddcccccccccddddddddddddd90cddddddddd900ccccc955cc55ccccccc
c1ddddcccccccccccdddddcccccccccccdddddcccccccccccdddddcccccccccccddd1dddcccccccccddddddccddddc00cddddddddd90cccccc999cc999cccccc
cd1ddddcccccccccccdddddcccccccccc1dddddcccccccccc1dddddccccccccccddd1dddcccccccccddddcccccccccccccdddddccccccccccccccccccccccccc
cdd1dddcccccccccccdddddccccccccccd1ddddccccccccccd1ddddcccccccccddddcd9ccccccccccddddccccccccccccccddddccccccccccccccccccccccccc
cdd1dddccccccccccccddddccccccccccd1ddddccccccccccdd1dddcccccccccddddc900cccccccccddddccccccccccccccddddccccccccccccccccc5555cccc
dddddddcccccccccccdddddcccccccccddd1dddcccccccccddd1dddcccccccccddddc00cccccccccddddccccccccccccccccdddcccccccccccccccc5999ccccc
dddcdddccccccccccc0dddccccccccccdddddddcccccccccdddddddcccccccccddddccccccccccccddddccccccccccccccccdddcccccccccccccccc5959ccccc
dddcdd9ccccccccccc0ddcccccccccccdddccddcccccccccdddccddcccccccccdddcccccccccccccdddccccccccccccccccccd90cccccccccccccff9999ccccc
099cc990cccccccccc099ccccccccccc99ccc99ccccccccc99ccc99ccccccccc99cccccccccccccc99ccccccccccccccccccc000ccccccccccccffff9959cccc
c00cc00cccccccccccc000cccccccccc0000c000cccccccc0000c000cccccccc000ccccccccccccc0000ccccccccccccccccc00ccccccccccccffff55f59cccc
ccc77ccc9cc77cc9cccccccccccccccc888cccccccccccccccccccccccccfccccccfcccccccccccccccccccccfffffffccccccc7cccccccccccfff555fcccccc
7cccccc7c97cc79c7c7777cccc7777ccc888c888ccc88888ccc5555cccccf4cccc4fcccccccccccccccccccc4f44444fcccccc76cccccccccccff555fccccccc
cc7cc7ccc779977cc777887cc777777ccc88888ccaaa88cccc5999ccccccf4cccc4fcccccc44444cc44444cc4fdddd4fccccc76ccccccccccccc7557cccccccc
cccccccc7c9779c7cc788887cc778877caaa88cca8aa0acccc5959ccccccf4cccc4fcccccc4ffffffffff4cc4fdddd4fffffff44cccccccccccfff59cccccccc
cccccccc7c9779c7c7788887c7778877a8aa0accaaa00a0ccc9999ccfffff4cccc4fffffcc4fccccccccf4cc4fdddd4fcc555ccccccccccccccc5599cccccccc
cc7cc7ccc779977ccc77887ccc77777caaa00a0cccc0ca0accc99cccc44444cccc44444ccc4fccccccccf4cc4fdddd4fcc76cccccccccccccccc555ccccccccc
7cccccc7c97cc79cc77777ccc7c777ccccc0ca0acc0ccccccccccccccccccccccccccccccc4fccccccccf4cc4fffffffc76ccccccccccccccccc55cccccccccc
ccc77ccc9cc77cc9cccccccccccccccccc0ccccccccccccccccccccccccccccccccccccccccfccccccccfccc4444444c76cccccccccccccccccc999ccccccccc
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
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001010101020202020000000000000000010101010202000100000000000000000101010100000000000000000000000001010101000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000020202020202020202020202020200000202020202020202020202020002000001010101010101010101010100000000010101010101010101010101000000000101010101010101010101010000000001010101010101010101010101000000
__map__
4141414141414141414141414141414141414141414141414040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040
4243727242437272424372724243727242437272424372724040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040
51535252525352525253525252535252525352525253fc524040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040
405140404040404040404040404040404040404040fcfd404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040
4040514040404040404040404040404040404040fcfd40404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040
40404051404040404040404040404040404040fcfd4040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040
404040405140404040404040404040404040fcfd404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040
5050505050505050505050505050505050505050505050504040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040
6061606160616061606160616061606160616061606160614040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040
4141414141414141414141414141414141414141414141414040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040
4141414141414141414141414141414141414141414141414040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040
4243727242437272424372724243727242437272424372724040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040
5153525252535252525352525253525252535252525352fc4040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040
40514040404040404040404040404040404040404040fc404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040
404051404040404040404040404040404040404040fc40404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040
4040405140404040404040404040404040404040fc4040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040
40404040514040404040404040404040404040fc404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040
5050505050505050505050505050505050505050505050504040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040
6061606160616061606160616061606160616061606160614040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040
7170707071707070717070707170707071707070717070704040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040
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
010100001475113751117510e7510d7510a7510875106751047510275101751007510075100701007010070100701007010070100701007010070100701007010070100701007010070100701007010070100701
010500000364500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005
00040000320501e050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010300000c6510c6510060100601006010060100601006010c6510c6510060100601006010060100601006010c6510c6510060100601006010060100601006010c6510c651006010060100601006010060100601
__music__
01 00034344
00 00034344
00 01034344
00 00034344
02 02034344
01 04064844
00 05074844

