pico-8 cartridge // http://www.pico-8.com
version 29
__lua__
-- lowrez
-- andrew stephens

poke(0x5f2c,3)

ticks=0

-------------------------------
-- input
-------------------------------
input={
	x=0,y=0,btn4=false,btn5=false,
	update=function(self)
		if btn(⬅️) and btn(➡️)==false then
			self.x=-1
		elseif btn(➡️) and btn(⬅️)==false then
			self.x=1
		else
			self.x=0
		end
		if btn(⬆️) and btn(⬇️)==false then
			self.y=-1
		elseif btn(⬇️) and btn(⬆️)==false then
			self.y=1
		else
			self.y=0
		end
		if btn(4) then
			self.btn4=true
		else
			self.btn4=false
		end
	end
}

-------------------------------
-- player shots
-------------------------------
pshots={
	draw=function(self)
		for shot in all(pshots) do
			if shot.anim==2 then
				spr(5,shot.x,shot.y)
			end
		end
	end,
	new=function(self,x,y,sx,sy)
		shot={
			x=x,
			y=y,
			sx=sx or 0,
			sy=sy or 0,
			anim=1,
		}
		add(self,shot)
	end,
	update=function(self)
		for shot in all(pshots) do
			shot.anim+=1
			if shot.anim>2 then
				shot.anim=1
			end
			shot.x+=shot.sx
			shot.y+=shot.sy
			if shot.y<-16 then
				del(self,shot)
			end
		end
	end
}

-------------------------------
-- osd
-------------------------------
osd={
	draw=function(self)
		print("0000",0,0,7)
		spr(10,57,55)
	end
}

-------------------------------
-- player
-------------------------------
player={
	x=28,y=56,anim=1,pods={},
	btn4=false,btn5=false,
	multi=3,
	animate=function(self)
		if ticks%2==0 then
			self.anim+=1
			if self.anim>2 then
				self.anim=1
			end
		end
	end,
	draw=function(self)
		spr(self.anim,self.x,self.y)
	end,
	update=function(self)
		self:animate()
		if input.x then
			self.x+=input.x
		end
		if input.y then
			self.y+=input.y
		end
		if self.x<0 then
			self.x=0
		elseif self.x>56 then
			self.x=56
		end
		if self.y<0 then
			self.y=0
		elseif self.y>56 then
			self.y=56
		end
		if input.btn4 and self.btn4==false then
			pshots:new(self.x,self.y,0,-1)
			if self.multi>0 then
				pshots:new(self.x,self.y,-.1,-1)
				pshots:new(self.x,self.y,.1,-1)
			end
			if self.multi>1 then
				pshots:new(self.x,self.y,-.2,-1)
				pshots:new(self.x,self.y,.2,-1)
			end
			if self.multi>2 then
				pshots:new(self.x,self.y,-.3,-1)
				pshots:new(self.x,self.y,.3,-1)
			end
		end
		self.btn4=input.btn4
	end
}

-------------------------------
-- stars
-------------------------------
stars={
	init=function(self)
		for i=1,32 do
			local star={
				x=flr(rnd(64)),
				y=flr(rnd(64)),
				s=rnd(2)+.1
			}
			add(self,star)
		end
	end,
	update=function(self)
		for star in all(self) do
			star.y+=star.s
			if star.y>64 then
				star.y=-1
				star.x=flr(rnd(64))
				star.s=rnd(2)+.1
			end
		end
	end,
	draw=function(self)
		for star in all(self) do
			pset(star.x,star.y,13)
		end
	end
}

-------------------------------
-- core functions
-------------------------------

function _init()
	stars:init()
end

function _update60()
	ticks+=1
	input:update()
	player:update()
	pshots:update()
	stars:update()
end

function _draw()
	cls(1)
	stars:draw()
	osd:draw()
	pshots:draw()
	player:draw()
end


__gfx__
0000000000067000000670000000000000777700000000000088880000000000000000000000000000888800000ee00000000000000000000000000000000000
00000000006cc700006cc700000990000777767000000000088ee8800000000000000000000000000088880000077000000e0000000000000000000000000000
00700700006cc700006cc7000099a900777777670003300088effe880000000000000000000ee00000eeee00ef0000fe00007000000000000000000000000000
00077000066cc670066cc67009999a9077667767000bb0008ef77fe80000000000000000000ee00000eeee00f700007f0e0000e0000770000000000000000000
00077000066666700666667009999a9077667777000770008ef77fe800000000000ff000000ff00000ffff000000000000700700007007000000000000000000
0070070066600667666776670099990077777777000000008ef77fe800000000000ff000000ff00000ffff000000000000000000000000000000000000000000
0000000066000067669aa96700099000077667700000000088e77e88007777000077770000777700007777000000000000000000000000000000000000000000
00000000600000076009900700000000007777000000000008e77e80007777000077770000777700007777000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000008877880000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000877800000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000877800000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000007000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000007000000000000000000000000000000000000000000000000000000000000000000000000000
