pico-8 cartridge // http://www.pico-8.com
version 29
__lua__
-- ============================
-- balloon fight
-- andrew stephens
-- july 2020
-- ============================

test_mode=true

gravity=0.1
force=gravity*2
ticks=0

function _init()

end

function _update60()
	ticks=ticks+1
	player:update()
end

function _draw()
	cls(2)
	input:get()
	player:draw()
	print(player.velocity.y)
end

input={
	x,y,b,
	get=function(self)
		self.x=0
		self.y=0
		self.b=false
		if btn(⬅️) and btn(➡️)==false then
			self.x=-1
		elseif btn(➡️) and btn(⬅️)==false then
			self.x=1
		else
			self.x=nil
		end
		if btn(4) or btn(5) then
			self.b=true
		end
	end
}

player={
	x=0,
	y=0,
	anim=1,
	balloons=2,
	ball_anim=1,
	direction=1,
	grounded=false,
	running=false,
	sprs={
		standing={0,2,0,4},
		running={6,8,6,10},
		flying={32,34,32,36},
	},
	velocity={x=0,y=0},
	animate=function(self)
		if ticks%5==0 then
			self.anim+=1
			if self.anim>4 then
				self.anim=1
			end
		end
		if ticks%10==0 then
			self.ball_anim+=1
			if self.ball_anim>4 then
				self.ball_anim=1
			end
		end
	end,
	update=function(self)
		if input.x then
			self.direction=input.x
			if self.grounded then
				self.running=true
				self.velocity.x=0
				self.x+=self.direction
			else
				self.velocity.x+=input.x*0.1
			end
		else
			self.running=false
		end
		self.x+=self.velocity.x
		if self.x<-8 then
			self.x=119
		elseif self.x>119 then
			self.x=-8
		end

		if input.b then
			self.grounded=false
			self.velocity.y-=force
		end

		if self.grounded==false and
				self.y<112 then
			self.velocity.y+=gravity
		else
			self.y=108
			self.grounded=true
		end

		self.y+=self.velocity.y
		
		self:animate()
	end,
	draw=function(self)
		local sprite
		local flip_x=false
		if self.direction==1 then
			flip_x=true
		end
		if self.grounded then
			if self.running then
				sprite=self.sprs.running[self.anim]
			else
				sprite=self.sprs.standing[self.ball_anim]
			end
		else
			sprite=self.sprs.flying[1]
		end

		spr(sprite,self.x,self.y,2,2,flip_x)
	end
}
__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000880088000000000088000000000000000000880000000000088008800000000008800880000000000880088000000000000000000000000000000000000
000088f828f80000000088f8288000000000088088f800000000088f828f80000000088f828f80000000088f828f800000000000000000000000000000000000
0008888f828f80000008888f82f80000000088f8288f800000008888f828f80000008888f828f80000008888f828f80000000000000000000000000000000000
000888888288800000088888828f80000008888f8288800000008888882888000000888888288800000088888828880000000000000000000000000000000000
000088882888000000008888288f8000000888888288000000000888828880000000088882888000000008888288800000000000000000000000000000000000
00000880088000000000088088880000000088882880000000000088008800000000008800880000000000880088000000000000000000000000000000000000
0000007ddd7000000000007ddd8000000000088ddd70000000000ddd0070000000000ddd0070000000000ddd0070000000000000000000000000000000000000
0000000dddd000000000000dddd000000000000dddd0000000000dddd700000000000dddd700000000000dddd700000000000000000000000000000000000000
000000fffdd00000000000fffdd00000000000fffdd000000000fffdd00000000000fffdd00000000000fffdd000000000000000000000000000000000000000
0000000ffd0000000000000ffd0000000000000ffd00000000000ffd0000000000000ffd0df0000000000ffd0000000000000000000000000000000000000000
000000d888d00000000000d888d00000000000d888d0000000000888d0000000000fd888dff00000000ff8d80000000000000000000000000000000000000000
00000fd888fd000000000fd888fd000000000fd888fd00000000f88fd0000000000ff88800000000000fdd880000000000000000000000000000000000000000
00000f8888ff000000000f8888ff000000000f8888ff00000000f88ff00000000000888880000000000088888100000000000000000000000000000000000000
00000088088000000000008808800000000000880880000000001108800000000001100888100000000088088100000000000000000000000000000000000000
00000011011000000000001101100000000000110110000000000011000000000000000001100000000110000000000000000000000000000000000000000000
00000088008800000000008800880000000000880088000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000088f828f80000000088f828f80000000088f828f800000000000000000000000000000000000000000000000000000000000000000000000000000000000
00008888f828f80000008888f828f80000008888f828f80000000000000000000000000000000000000000000000000000000000000000000000000000000000
00008888882888000000888888288800000088888828880000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000888828880000000088882888000000008888288800000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000088008800000000008800880000000000880088000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000070070000000000007007000000000000700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000ddd7000000000000ddd7000000000000ddd7000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000dddd000000000000dddd000000000000dddd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000fffdd00000000000fffddff000000000fffdd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000ffd0df0000000000ffd0df0000000000ffd0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000888dff0000000000888d000000000000888d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000088800000000000008880000000000000888df0000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000d888000000000000d888000000000000d888ff0000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000dd80000000000000dd80000000000000dd80000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000008800000000000000000000000000000000000000000000000008800000000000000880000000000000088000000000000000000000000000000000000
00000088f80000000000000880000000000000088000000000000000088f800000000000088f800000000000088f800000000000000000000000000000000000
000008888f80000000000088f800000000000088f8000000000000008888f800000000008888f800000000008888f80000000000000000000000000000000000
0000088888800000000008888f800000000008888f80000000000000888888000000000088888800000000008888880000000000000000000000000000000000
0000008888000000000008888f800000000008888f80000000000000088880000000000008888000000000000888800000000000000000000000000000000000
00000008800000000000008888000000000000888800000000000000008800000000000000880000000000000088000000000000000000000000000000000000
0000000ddd0000000000000ddd0000000000000ddd00000000000ddd0070000000000ddd0070000000000ddd0070000000000000000000000000000000000000
0000000dddd000000000000dddd000000000000dddd0000000000dddd700000000000dddd700000000000dddd700000000000000000000000000000000000000
000000fffdd00000000000fffdd00000000000fffdd000000000fffdd00000000000fffdd00000000000fffdd000000000000000000000000000000000000000
0000000ffd0000000000000ffd0000000000000ffd00000000000ffd0000000000000ffd0df0000000000ffd0000000000000000000000000000000000000000
000000d888d00000000000d888d00000000000d888d0000000000888d000000000000888dff00000000ff8d80000000000000000000000000000000000000000
00000fd888fd000000000fd888fd000000000fd888fd00000000f88fd00000000000088800000000000fdd880000000000000000000000000000000000000000
00000f8888ff000000000f8888ff000000000f8888ff00000000f88ff00000000000888880000000000088888100000000000000000000000000000000000000
00000088088000000000008808800000000000880880000000001108800000000001100888100000000088088100000000000000000000000000000000000000
00000011011000000000001101100000000000110110000000000011000000000000000001100000000110000000000000000000000000000000000000000000
00000088000000000000008800000000000000880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000088f800000000000088f800000000000088f8000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00008888f800000000008888f800000000008888f800000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00008888880000000000888888000000000088888800000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000888800000000000088880000000000008888000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000088000000000000008800000000000000880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000070000000000000007000000000000000700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000ddd0000000000000ddd0000000000000ddd0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000dddd000000000000dddd000000000000dddd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000fffdd00000000000fffddff000000000fffdd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000ffd0df0000000000ffd0df0000000000ffd0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000888dff0000000000888d000000000000888d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000088800000000000008880000000000000888df0000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000d888000000000000d888000000000000d888ff0000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000dd80000000000000dd80000000000000dd80000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
