pico-8 cartridge // http://www.pico-8.com
version 29
__lua__
gravity=2
jump_force=3
jump_steps=jump_force*3
left=-1
right=1
ticks=0

input={
	x=0,y=0,att=false,jmp=false,
	update=function(self)
		if btn(⬆️) and btn(⬇️)==false then
			self.y=-1
		elseif btn(⬇️) and btn(⬆️)==false then
			self.y=1
		else
			self.y=0
		end
		if btn(⬅️) and btn(➡️)==false then
			self.x=-1
		elseif btn(➡️) and btn(⬅️)==false then
			self.x=1
		else
			self.x=0
		end
		if btn(4) then
			self.att=true
		else
			self.att=false
		end
		if btn(5) then
			self.jmp=true
		else
			self.jmp=false
		end
	end,
}

player={
	anim=0,x=0,y=0,dr=right,
	duck=false,jump=0,
	anim={
		standing=1,
		running=1
	},
	sprs={
		standing={0,2},
		running={4,6,4,8},
		attacking={32,34},
		runattack={10,12,10,14},
		ducking=36,
		duckattack=38,
		jumping={40,42,44},
	},
	animate=function(self)
		if ticks%20==0 then
			self.anim.standing+=1
			if self.anim.standing>2 then
				self.anim.standing=1
			end
		end
		if ticks%10==0 then
			self.anim.running+=1
			if self.anim.running>4 then
				self.anim.running=1
			end
		end
	end,
	update=function(self)
		self.y+=gravity
		if self.jump>0 then
			self.y-=jump_force
			self.jump-=1
		end
		self:animate()
		if input.jmp and self.jump==0 then
			self.jump=jump_steps
		end
		if input.y>0 then
			self.duck=true
		else
			self.duck=false
		end
		if input.x~=0 then
			self.dr=input.x
			if self.duck==false then
				self.x+=input.x
			end
		end
	end,
	draw=function(self)
		local sprite
		if self.jump>0 then
			local index=self.jump/3+1
			sprite=self.sprs.jumping[index]				
		elseif self.duck then
			if input.att then
				sprite=self.sprs.duckattack
			else
				sprite=self.sprs.ducking
			end
		elseif input.x==0 then
			if input.att then
				sprite=self.sprs.attacking[self.anim.standing]
			else
				sprite=self.sprs.standing[self.anim.standing]
			end
		else
			if input.att then
				sprite=self.sprs.runattack[self.anim.running]
			else
				sprite=self.sprs.running[self.anim.running]
			end
		end
		local flip_x=false
		if self.dr==left then
			flip_x=true
		end
		spr(sprite,self.x,self.y,2,2,flip_x)
	end
}

function _update60()
	ticks+=1
	input:update()
	player:update()
end

function _draw()
	cls(12)
	player:draw()
end
__gfx__
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccc787cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccc8ccccccccccccc787cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccc666666cccccccccccc8cccccccccccccccccccccccccccc787ccccccccccccc787ccccccccccccccccccccccccccccc787ccccccccccccc787ccccccccc
cccc6c67575cccccccccc666666ccccccccc787cccccccccccccccc8ccccccccccccccc8cccccccccccc787cccccccccccccccc8ccccccccccccccc8cccccccc
cccc6c67777ccccccccc6c67575cccccccccccc8ccccccccccccc666666cccccccccc666666cccccccccccc8ccccccccccccc666666cccccccccc666666ccccc
ccccc665556ccccccccc6c67777cccccccccc666666ccccccccc6c66675ccccccccc6c66675cccccccccc666666ccccccccc6c66675ccccccccc6c66675ccccc
ccccc556865cccccccccc665556ccccccccc6c66675ccccccccc6c66677ccccccccc6c66677ccccccccc6c66675ccccccccc6c66677ccccccccc6c66677ccccc
cccc5c5555c5ccccccccc556865ccccccccc6c66677cccccccccc666556cccccccccc666556ccccccccc6c66677cccccccccc666556cccccccccc666556ccccc
cccc5cc55cc5cccccccc55555555ccccccccc666556cccccccccccc666ccccccccccccc666ccccccccccc666556c777cccccccc666cc777cccccccc666cc777c
cccc77888877cccccccc77c55c77ccccccccccc666cccccccccccc55577ccccccc7755555c77ccccccccccc6665577cccccccc55555577cccc775555555577cc
cccc77888877cccccccc77888877cccccccccc5555ccccccccccc885577ccccccc77c8855577cccccccccc5555ccccccccccc88555cccccccc77c8855ccccccc
ccccc88cc88cccccccccc888888cccccccccc888577cccccccccc7877cccccccc447c888ccccccccccccc888577cccccccccc7877cccccccc447c888cccccccc
ccccc7cccc7cccccccccc78cc87cccccccccc788c77ccccccccc7cc7744cccccc44c7ccc7cccccccccccc788c77ccccccccc7cc7744cccccc44c7ccc7ccccccc
ccc444cccc444cccccc444cccc444cccccccc444cccccccccccc444cc44cccccc44cccccc444ccccccccc444cccccccccccc444cc44cccccc44cccccc444cccc
ccc444cccc444cccccc444cccc444cccccccc444cccccccccccc444cccccccccccccccccc444ccccccccc444cccccccccccc444cccccccccccccccccc444cccc
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc787ccccccccccccc787ccccccccccccc787ccccccccccccc787cccccccc
ccccc787ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc8ccccccccccccccc8ccccccccccccccc8ccccccccccccccc8cccccccc
ccccccc8ccccccccccccc787ccccccccccccccccccccccccccccccccccccccccccccc666666cccccccccc666666cccccccccc666666cccccccccc666666ccccc
ccccc666666cccccccccccc8cccccccccccccccccccccccccccccccccccccccccccc6c67575ccccccccc6c67575ccccccccc6c67575ccccccccc6c67575ccccc
cccc6c67575cccccccccc666666ccccccccccccccccccccccccccccccccccccccccc6c67777ccccccccc6c67777ccccccccc6c67777ccccccccc6c67777ccccc
cccc6c67777ccccccccc6c67575cccccccccccccccccccccccccccccccccccccccccc6655567ccccccccc665556cccccccccc665556cccccccccc665556c777c
ccccc665556ccccccccc6c67777cccccccccc787ccccccccccccc787cccccccccccc77568677cccccccccc5686ccccccccccc556865ccccccccccc56865577cc
ccccc55686cc777cccccc665556c777cccccccc8ccccccccccccccc8cccccccccccc775555ccccccccccc775557ccccccccc775555c77cccccccc77555cccccc
cccc5c55555577ccccccc556865577ccccccc666666cccccccccc666666cccccccccccc55cccccccccccc775557ccccccccc77c55cc77cccccccc77555cccccc
cccc5cc55ccccccccccc55c555cccccccccc6c67575ccccccccc6c67575ccccccccccc88887ccccccccccc8448844ccccccccc8888cccccccccccc8448844ccc
cccc778888cccccccccc77c55ccccccccccc6c67777ccccccccc6c67777cccccccccc888844ccccccccccc444c444ccccccccc7887cccccccccccc444c444ccc
cccc7788888ccccccccc778888ccccccccccc665556cccccccccc665556c777cccccc88cc44ccccccccccc44cc44ccccccccccc7447c44cccccccc44cc44cccc
ccccc88cc88cccccccccc888888ccccccccccc5686cccccccccccc56865577cccccccc7cc44cccccccccccccccccccccccccccc444c444cccccccccccccccccc
ccccc7cccc7cccccccccc78cc87cccccccccc5775577ccccccccc57755ccccccccccc47cccccccccccccccccccccccccccccccc44cc44ccccccccccccccccccc
ccc444cccc444cccccc444cccc444ccccccc48778577cccccccc487787ccccccccccc44ccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccc444cccc444cccccc444cccc444ccccccc444c444ccccccccc444c444cccccccccc44ccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
