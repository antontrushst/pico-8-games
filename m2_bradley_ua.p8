pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
-- main --

function _init()
	sys_init()
	menue_init()
	enemies_init()
	env_init()
end

-- update loop --
function _update()
	if current_scene=="menue" then
		menu:update()
	elseif current_scene=="play" then
		plr:update()
		pop_enemies()		
		update_tracks()
		update_enemies()
		update_player_bullets()
		update_enemy_bullets()
		update_particles()
		update_bodies()
		update_trees()
		update_collects()
		buls_enem_resol()
		en_bulls_plr_col()
		buls_trees_col()
		enemy_enemy_col()
		tank_tree_col()
		spawn_collects()
		plr_collects_col()
		switch()
		pes_patron:update()
		mine:update()
		if special_is_on then
			special:update()
		end
	end
end

-- draw loop --
function _draw()
	cls(6)
	if current_scene=="menue" then
		menu:draw()
	elseif current_scene=="play" then
		palt(0,true)
		palt(11,false)
		draw_tracks()
		draw_dest_tanks()
		draw_bodies()
		draw_particles()
		draw_misc()
		draw_trees()
		draw_collectibles()
		draw_enemies()
		draw_player_bullets()
		draw_enemy_bullets()
		if special_is_on then
			special:draw()
		end
		pes_patron:draw()
		mine:draw()
		plr:draw()
		game_over()
		win()
		restart()
		ui:draw()
	end
end
-->8
-- systems --
function sys_init()
	play=true
	g_over=false
	victory=false
	particles={}
	tracks={}
	en_bulls={}
	to_kill=1
	en_num=to_kill
	en_killed=0
	current_scene="menue"
	level=10
end

function start_level(lvl)
	-- clear tables --
	foreach(en_bulls,function(obj)del(en_bulls,obj)end)
 foreach(buls,function(obj)del(buls,obj)end)
 foreach(enemies,function(obj)del(enemies,obj)end)
	foreach(trees,function(obj)del(trees,obj)end)
	foreach(misc,function(obj)del(misc,obj)end)
	foreach(bodies,function(obj)del(bodies,obj)end)
	foreach(particles,function(obj)del(particles,obj)end)
	foreach(tracks,function(obj)del(tracks,obj)end)
	foreach(dest_tanks,function(obj)del(dest_tanks,obj)end)
	foreach(collects,function(obj)del(collects,obj)end)
	-- set enemies to kill --
	to_kill=ceil(rnd(20)+10)*lvl
	en_num=to_kill
	g_over=false
	-- set environment --
	env_init(lvl)
end

-- switch to next level --
function switch()
	if play==false and 
	g_over==false and
	victory and
	btnp(5) then
		play=true
		victory=false
		level+=1
		start_level(level)
	end
end

-- collision check --
function collision(x1, x2,
																			y1, y2,
																			ax1,ax2,
																			ay1,ay2)
	x=x2-x1
	ax=ax2-ax1
	y=y2-y1
	ay=ay2-ay1
	
	x_dis=flr(abs((x1+x/2)-
											(ax1+ax/2)))
	y_dis=flr(abs((y1+y/2)-
											(ay1+ay/2)))
	
	if x_dis < (x+ax)/2 and
				y_dis < (y+ay)/2 then
		return true
	end
	return false
end

-- bullets-enemies collision
-- resolution
function buls_enem_resol()
	for e in all(enemies) do
		for b in all(buls) do
			if collision(e.coll_x1,
																e.coll_x2,
																e.coll_y1,
																e.coll_y2,
																b.coll_x1,
																b.coll_x2,
																b.coll_y1,
																b.coll_y2) then
				if e.tag=="meat" then
					if rnd(2)>1 then
						sfx(6,3)
					else
						sfx(7,3)
					end
					add_body(e.x,e.y,0,-1,.8)
					for i=0,flr(rnd(30)),1 do
						add_part(e.x, e.y,
															rnd(10)-3,
															rnd(20)-20,
															8, 100,0.5,0.5)
					end
					en_killed+=1
					del(enemies, e)
					b.life-=flr(rnd(350))
				else
					for i=0,flr(rnd(5)),1 do
						add_part(e.x+10, e.y+10,
															rnd(10)-5,
															rnd(10),
															13,2,0.5,0.5)
						add_part(e.x+10, e.y+10,
															rnd(20)-10,
															rnd(10),
															7,2,0.5,0.5)
					end
					add_part(e.x+10,e.y+10,
														rnd(20)-10,
														rnd(10)+10,
														9,30,1,1)
					if rnd(2)>1 then
						sfx(4,3)
					else
						sfx(5,3)
					end
					e.sprt=74
					e.hp-=5
					b.life-=300
				end
			end
		end
	end
end

-- enemy bullets vs player
-- collision resolution
function en_bulls_plr_col()
	for eb in all(en_bulls) do
		if collision(eb.coll_x1,
															eb.coll_x2,
															eb.coll_y1,
															eb.coll_y2,
															plr.coll_x1,
															plr.coll_x2,
															plr.coll_y1,
															plr.coll_y2) then
			if eb.tag=="tank" then
				plr.hp-=10
			else
				plr.hp-=2
			end
			if plr.hp<=0 then
				sfx(8,2)
				for i=0,30,1 do
					add_part(plr.x+8, plr.y+10,
														rnd(20)-10,rnd(20)-10,
														9, 3, 0.8,0.8)
					add_part(plr.x+8, plr.y+10,
														rnd(20)-10,rnd(20)-10,
														1, 3, 0.8,0.8)
				end
				explode(plr.cx,plr.cy,30)
			end
			del(en_bulls, eb)
		end
	end
end

-- enemy vs enemy
-- collision resolution --
function enemy_enemy_col()
	for e1 in all(enemies) do
		for e2 in all(enemies) do
			if e1.tag=="meat" then
				break
			end
			if collision(e1.coll_x1,
																e1.coll_x2,
																e1.coll_y1,
																e1.coll_y2,
																e2.coll_x1,
																e2.coll_x2,
																e2.coll_y1,
																e2.coll_y2) and
						e1.id != e2.id then
				if e1.tag=="tank" and
				   e2.tag=="meat" then
				 if e1.dx!=0 then
				 	add_body(e2.x,e2.y,0,-1,.2)
				 	del(enemies,e2)
				 	e1.track_col=8
				 else
				 	e2.dx=0
				 	e2.dy=0
				 end
				elseif e1.tag=="tank" and
											e2.tag=="tank" then
					e1.dx=0
					e2.dx=0
				end
			end
		end
	end
end

-- tank vs tree
-- collision resolution
function tank_tree_col()
	for e in all(enemies) do
		if e.tag!="tank" then
			break
		end
		
		for t in all(trees) do
			if collision(t.coll_x1,
																t.coll_x2,
																t.coll_y1,
																t.coll_y2,
																e.coll_x1,
																e.coll_x2,
																e.coll_y1,
																e.coll_y2) then
				e.hp-=30
				t.hp-=200
				for i=0,flr(rnd(10)),1 do
					add_part(t.x+6, t.y+8,
														rnd(10)-3,
														rnd(20)-10,
														4, 100, 0.5, 0.5)
					add_part(t.x+6, t.y+8,
														rnd(10)-3,
														rnd(20)-10,
														5, 100, 0.5, 0.5)
				end
			end
		end
	end
end

-- bullets vs trees
-- collision resolution
function buls_trees_col()
	for tree in all(trees) do
		for b in all(buls) do
			if collision(tree.coll_x1,
																tree.coll_x2,
																tree.coll_y1,
																tree.coll_y2,
																b.coll_x1,
																b.coll_x2,
																b.coll_y1,
																b.coll_y2) then
				tree.hp-=20
				b.life-=flr(rnd(350))
				for i=0,flr(rnd(10)),1 do
					add_part(tree.x+6, tree.y+8,
														rnd(10)-3,
														rnd(20)-20,
														4, 100, 0.5, 0.5)
					add_part(tree.x+6, tree.y+8,
														rnd(10)-3,
														rnd(20)-20,
														5, 100, 0.5, 0.5)
				end							
			end
		end
		
		for b in all(en_bulls) do
			if b.tag!="tank" then
				break
			end
			if collision(tree.coll_x1,
																tree.coll_x2,
																tree.coll_y1,
																tree.coll_y2,
																b.coll_x1,
																b.coll_x2,
																b.coll_y1,
																b.coll_y2) then
				tree.hp-=50
				b.life-=300
				for i=0,flr(rnd(10)),1 do
					add_part(tree.x+6, tree.y+8,
														rnd(10)-3,
														rnd(20),
														4, 100, 0.5, 0.5)
					add_part(tree.x+6, tree.y+8,
														rnd(10)-3,
														rnd(20),
														5, 100, 0.5, 0.5)
				end							
			end
		end
	end
end

-- game over system --
function game_over()
	if plr.hp <= 0 then
		for b in all(en_bulls) do
			del(en_bulls,b)
		end
		play=false
		g_over=true
		rectfill(30,50,97,77,13)
		rect(30,50,97,77,1)
		print("game over", 47, 54, 1)
		print("game over", 48, 54, 8)
		print("enemies killed",36,62,1)
		print(en_killed,66-#tostr(en_killed)*2,70,1)
	else	
		for e in all(enemies) do
			if e.y >= 94 then
				play=false
				g_over=true
				rectfill(30,50,97,77,13)
				rect(30,50,97,77,1)
				print("game over", 47, 54, 1)
				print("game over", 48, 54, 8)
				print("enemies killed",36,62,1)
				print(en_killed,66-#tostr(en_killed)*2,70,1)
			end
		end
	end
end

-- win system --
function win()
	if count(enemies) <= 0 and
	en_num==0 then
		play=false
		victory=true
		print(level,62-#tostr(level)*2,40,1)
		print("level",52,46,1)
		print("victory", 49, 55, 4)
		print("victory", 48, 54, 9)
		print("press x to continue",
								25,64,1)
		for b in all(en_bulls) do
			del(en_bulls,b)
		end
	end
end

-- restart --
function restart()
	if btn(5) and g_over then
		run()
	end
end

-- explosion --
function explode(_x,_y,_r)
	for e in all(enemies) do
		if e.tag=="tank" then goto skip end
		local diffx=e.cx-_x
		local diffy=e.cy-_y
		local dist=sqrt(diffx*diffx+diffy*diffy)
		if dist<_r then
			local normx=diffx/dist
			local normy=diffy/dist
			add_body(e.x,e.y,normx,normy,.9)
			en_killed+=1
			del(enemies,e)
			--t0_kill-=1
		end
	::skip::
	end
end

-- particles system --
function add_part(_x,_y,_dx,_dy,_col,_life,_div_x,_div_y)
	add(particles,{
		x=_x, y=_y, dx=_dx, dy=_dy,
		div_x=_div_x, div_y=_div_y,
		col=_col, life=_life,
		
		draw=function(self)
			pset(self.x, self.y, self.col)
		end,
		
		update=function(self)
			if self.life <= 0 then
				del(particles,self)
			else
				self.life-=1
			end
			self.x+=self.dx
			self.y+=self.dy
			if self.dx > 0.1 or
						self.dx < -0.1 then
				self.dx*=self.div_x
			else
				self.dx=0
			end
			if self.dy > 0.1 or
						self.dy < -0.1 then
				self.dy*=self.div_y
			else
				self.dy=0
			end
		end
	})
end

ui={
	draw=function(self)
		-- ui background
		rectfill(0,118,128,128,13)
		-- hp text
		print("hp",4,120,1)
		-- hp background
		rectfill(14,120,51,124,1)
		-- hp
		if plr.hp > 0 then
			rectfill(16,121,16+plr.hp/3,123,8)
		end
		-- specials
		if plr.spec_count>=3 then
			rectfill(27,125,28,126,9)
			rect(26,125,29,127,1)
		end
		if plr.spec_count>=2 then
			rectfill(22,125,23,126,9)
			rect(21,125,24,127,1)
		end
		if plr.spec_count>=1 then
			rectfill(17,125,18,126,9)
			rect(16,125,19,127,1)
		end
		-- ammo
		print("ammo:",54,120,1)
		print(plr.ammo,75,121,1)
		print(plr.ammo,74,120,9)
		-- kill remaining
		if to_kill > 99 then
			print("enms:",92,120,1)
			print(count(enemies),113,121,1)
			print(count(enemies),112,120,9)
		elseif to_kill > 9 then
		 print("enms:",96,120,1)
			print(count(enemies),117,121,1)
			print(count(enemies),116,120,9)
		else
			print("enms:",100,120,1)
			print(count(enemies),121,121,1)
			print(count(enemies),120,120,9)
		end
	end
}

-- tracks animation --
function add_tracks(_x,_y,_col)
	add(tracks, {
		x=_x, y=_y,
		spr_n=51,
		life=100,
		
		draw=function(self)
			pal(13,_col)
			spr(self.spr_n,
							self.x, self.y)
			pal()
		end,
		
		update=function(self)
			if self.life <= 0 then
				del(tracks, self)
			else
				self.life-=1
			end
		end
	})
end

-- add enemy bullets --
function add_en_bull(_x,_y,_tag)
	add(en_bulls, {
		x=_x, y=_y, dy=2, tag=_tag,
		col=4, life=200,
		tracer=0, tracer_col=4,
		coll_x1=0, coll_x2=0,
		coll_y1=0, coll_x1=0,
		draw_coll=false,
		
		draw=function(self)
			pset(self.x, self.y,self.col)
			rect(self.x,
								self.y+self.tracer,
								self.x,
								self.y+1,
								self.tracer_col)
			if self.draw_coll then
				rect(self.coll_x1,
									self.coll_y1,
									self.coll_x2,
									self.coll_y2, 12)
			end
		end,
		
		update=function(self)
			if self.tag=="tank" then
				self.dy=6
				--self.life/=1
				self.tracer=-10
				self.tracer_col=9
			end
			if self.life <= 0 then
				del(en_bulls, self)
			else
				self.life-=1
			end
			self.y+=self.dy
			self.coll_x1=self.x
			self.coll_x2=self.x
			self.coll_y1=self.y-self.dy
			self.coll_y2=self.y
		end
	})
end
-- player-collectibles collision
function plr_collects_col()
	for c in all(collects) do
		if collision(plr.coll_x1,
															plr.coll_x2,
															plr.coll_y1,
															plr.coll_y2,
															c.coll_x1,
															c.coll_x2,
															c.coll_y1,
															c.coll_y2) then
			if c.tag=="medkit" then
				if plr.hp<=50 then
					plr.hp+=50
				else
					plr.hp+=100-plr.hp
				end
				sfx(11)
				del(collects,c)
			elseif c.tag=="ammo" then
				sfx(12)
				plr.ammo+=100
				del(collects,c)
			elseif c.tag=="special" then
				sfx(10)
				plr.spec_count+=1
				del(collects,c)
			end
		end
	end
end
-- collectibles --
medkit_count=0
ammo_count=0
special_count=0
function spawn_collects()
	difficulty_coeff=1+level/5
	if flr(en_killed/(20*difficulty_coeff))-medkit_count>=1 then
		if rnd(2)>1 then
			add_collec(rnd(119),
													rnd(5)+105,
													"medkit")
			medkit_count+=1
		end
	end
	if flr(en_killed/(15*difficulty_coeff))-ammo_count>=1 then
		add_collec(rnd(119),
														rnd(5)+105,
														"ammo")
		ammo_count+=1
	end
	if flr(en_killed/(30*difficulty_coeff))-special_count>=1 then
		if rnd(3)<1 then
			add_collec(rnd(119),
															rnd(5)+105,
															"special")
			special_count+=1
		end
	end
end

-- updates -------------------
function update_enemies()
	for e in all(enemies) do
		e:update()
	end
end
function update_tracks()
	for t in all(tracks) do
		t:update()
	end
end
function update_player_bullets()
	for b in all(buls) do
		b:update()
	end
end
function update_enemy_bullets()
	for eb in all(en_bulls) do
		eb:update()
	end
end
function update_particles()
	for p in all(particles) do
		p:update()
	end
end
function update_bodies()
	for b in all(bodies) do
		b:update()
	end
end
function update_trees()
	for tree in all(trees) do
		tree:update()
	end
end
function update_collects()
	for c in all(collects) do
		c:update()
	end
end
-------------------------------
-- draws ----------------------
function draw_tracks()
	for t in all(tracks) do
		t:draw()
	end
end
function draw_bodies()
	for b in all(bodies) do
		b:draw()
	end
end
function draw_particles()
	for p in all(particles) do
		p:draw()
	end
end
function draw_misc()
	for m in all(misc) do
		m:draw()
	end
end
function draw_trees()
	for tree in all(trees) do
		tree:draw()
	end
end
function draw_enemies()
	for e in all(enemies) do
		e:draw()
	end
end
function draw_player_bullets()
	for b in all(buls) do
		b:draw()
	end
end
function draw_enemy_bullets()
	for eb in all(en_bulls) do
		eb:draw()
	end
end
function draw_dest_tanks()
	for dt in all(dest_tanks) do
		dt:draw()
	end
end
function draw_collectibles()
	for c in all(collects) do
		c:draw()
	end
end

patron=false
patron_count=1
pes_patron={
	x=-10,y=rnd(60)+20,dx=1,sprt=117,
	anim_timr_val=2,anim_timr=2,
	plan_timr=30, target_x=rnd(80)+20,
	draw=function(self)
		if patron and self.x<130 then
			palt(0,false)
			palt(11,true)
			spr(self.sprt,self.x,self.y)
			palt()
		end
	end,
	update=function(self)
		if patron and self.x<130 then
			if self.x<self.target_x then
				self.x+=self.dx
			elseif self.plan_timr>0 and
										mine.planted==false then
				self.sprt=119
				self.plan_timr-=1
				if self.plan_timr<=0 then
					self.sprt=117
					mine.coll_x1=self.x-2
					mine.coll_x2=self.x-2+5
					mine.coll_y1=self.y+5
					mine.coll_y2=self.y+8
				end
			else
				mine.planted=true
				self.x+=self.dx
			end
			if self.anim_timr<=0 and
						self.sprt!=119 then
				self.anim_timr=self.anim_timr_val
				if self.sprt==117 then
					self.sprt=118
				else
					self.sprt=117
				end
			else
				self.anim_timr-=1
			end
		end
	end
}
mine={
	coll_x1=0,coll_x2=0,
	coll_y1=0,coll_y2=0,
	sprt=120,planted=false,
	draw_coll=false, coll_col=8,
	draw=function(self)
		if self.planted then
			palt(0,false)
			palt(11,true)
			spr(self.sprt,
							self.coll_x1-1,
							self.coll_y1-5)
			if self.draw_coll then
				rect(self.coll_x1,
									self.coll_y1,
									self.coll_x2,
									self.coll_y2,
									self.coll_col)
			end
			palt()
		end
	end,
	update=function(self)
		if self.planted then
			for e in all(enemies) do
				if collision(self.coll_x1,
																	self.coll_x2,
																	self.coll_y1,
																	self.coll_y2,
																	e.coll_x1,
																	e.coll_x2,
																	e.coll_y1,
																	e.coll_y2) then
					sfx(8,2)
					for i=0,30,1 do
						add_part(self.coll_x1+2, self.coll_y1+1,
															rnd(20)-10,rnd(20)-10,
															9, 3, 0.8,0.8)
						add_part(self.coll_x1+2, self.coll_y1+1,
															rnd(20)-10,rnd(20)-10,
															1, 3, 0.8,0.8)
					end
					explode(self.coll_x1+2,self.coll_y1+1,100)
					for en in all(enemies) do
						if en.tag=="tank" then
							local diffx=en.cx-self.coll_x1+2
							local diffy=en.cy-self.coll_y1+1
							local dist=sqrt(diffx*diffx+diffy*diffy)
							if dist<100 then
								en.hp=0
							end
						end
					end
				end
			end
		end
	end
}
-->8
-- player --
plr={
	hp=100, x=63, y=100, scale=2,
	tx=60+8, ty=101, dx=0,
	speed=1, spr_n=1, t_spr=49,
	coll_x1=0, coll_x2=0, cx=0,
	coll_y1=0, coll_y2=0, cy=0,
	draw_coll=false,
	mov_frm_st=1,
	mov_frm_en=5,
	anim_timr=1,
	cross_col=6,
	atck_timr=0,
	atck_timr_val=3,
	trck_timr_val=2,
	trck_timr=0,
	ammo=100,
	spec_count=3,
		
	draw = function(self)
		if self.hp<=0 then
			self.spr_n=110
			self.t_spr=112
		end
		-- draw base --
		spr(self.spr_n,
						self.x,
						self.y,
						self.scale,
						self.scale)
		-- draw turret --
		spr(self.t_spr,
						self.tx,
						self.ty)
			
			-- draw collider --
		if self.draw_coll then
			rect(self.coll_x1,
								self.coll_y1,
								self.coll_x2,
								self.coll_y2, 11)
		end
		-- draw smoke --
		if self.hp<=0 then
			for i=0,3,1 do
				add_part(self.x+8,
													self.y+10,
													rnd(4)-2,
													rnd(10)-10,
													0, 5, .4,.8)
			end
			for i=0,3,1 do
				add_part(self.x+8,
													self.y+10,
													rnd(4)-2,
													rnd(10)-10,
													6, 5, .4,.4)
			end
		end
	end,
		
	update = function(self)
		-- hp cap --
		if self.hp>100 then
			self.hp=100
		end
		-- special cap --
		if self.spec_count>3 then
			self.spec_count=3
		end
		-- movement --
		self.dx = 0
		if btn(0) and play and
		self.x > -8 and
		special_is_on==false then
			sfx(1,1,0,2)
			self.dx -= self.speed
			if self.anim_timr <= 0 then
				if self.spr_n==1 then
					self.spr_n=5
				else
					self.spr_n-=2
				end
			else
				self.anim_timr-=1
			end
			if self.trck_timr <= 0 then
				add_tracks(self.x+12,
															self.y+8,13)
				self.trck_timr=self.trck_timr_val
			else
				self.trck_timr-=1
			end
		elseif btn(1) and play and
		self.x < 118 and
		special_is_on==false then
			sfx(1,1,0,2)
			self.dx += self.speed
			if self.anim_timr <= 0 then
				if self.spr_n==5 then
					self.spr_n=1
				else
					self.spr_n+=2
				end
			else
				self.anim_timr-=1
			end
			if self.trck_timr <= 0 then
				add_tracks(self.x+2,
															self.y+8,13)
				self.trck_timr=self.trck_timr_val
			else
				self.trck_timr-=1
			end
		end
		self.x += self.dx
		self.tx=self.x+5
			
		-- collider --
		self.coll_x1=self.x+1
		self.coll_x2=self.x+(8*self.scale-2)
		self.coll_y1=self.y+6
		self.coll_y2=self.y+(8*self.scale)
		-- center point update --
		self.cx=self.coll_x1+(self.coll_x2-self.coll_x1)/2
		self.cy=self.coll_y1+(self.coll_y2-self.coll_y1)/2
		-- attact --
		if btn(4) and play and
		self.atck_timr<=0 and
		special_is_on==false then
			add_bul(self.x+9, 
											self.y+2)
			if self.ammo>0 then
				self.ammo-=1
			end
			for i=0,flr(rnd(30)),1 do
				add_part(self.x+9,
													self.y+2,
													rnd(4)-2,
													rnd(5)-5,
													10, 3, 0.5,0.5)
			end
			for i=0,flr(rnd(30)),1 do
				add_part(self.x+9,
													self.y+2,
													rnd(6)-3,
													rnd(5)-5,
													7, 3, 0.5,0.5)
			end
			sfx(0,0,0,6)
			self.ty+=1
			self.t_spr=50
			self.spr_n+=6
			if self.ammo<=0 then
				self.atck_timr_val=15
			else
				self.atck_timr_val=3
			end
			self.atck_timr=self.atck_timr_val
		else
			self.ty=self.y+1
			self.t_spr=49
			if self.spr_n > 5 then
				self.spr_n-=6
			end
			self.atck_timr-=1
		end
		-- special --
		if btnp(5) and special_is_on==false and
		   self.spec_count>0 then
			special_is_on=true
			self.spec_count-=1
		end
		if btn(2) and btn(3) and btn(4) and patron==false and patron_count==1 then
			patron=true
			patron_count=0
		end
	end
}

-- player bullets --
buls={}
function add_bul(_x, _y)
	add(buls,{
		x=_x,	y=_y, dx=0, dy=-20,
		tracer=flr(rnd(6)+2),
		scale=1,
		coll_x1=0,	coll_x2=0,
		coll_y1=0, coll_y2=0,
		draw_coll=false,
		life=150, col=10,
			
		draw=function(self)
			-- draw bullet --
			pset(self.x,
								self.y,
								self.col)
			-- draw tracer --
			rect(self.x,
								self.y+1,
								self.x,
								self.y+self.tracer,
								10)
								
			-- draw collider --
			if self.draw_coll then
				rect(self.coll_x1,
									self.coll_y1,
									self.coll_x2,
									self.coll_y2, 7)
			end
		end,
			
		update=function(self)
			self.x += self.dx
			self.y += self.dy
			self.coll_x1=self.x
			self.coll_x2=self.x
			self.coll_y1=self.y
			self.coll_y2=self.y+20
			self.life -= 1
			if self.life <= 0 then
				del(buls, self)
			end
		end
	})
end

-- collectibles --
collects={}
function add_collec(_x,_y,_tag)
	add(collects,{
		x=_x, y=_y, sprt=55, tag=_tag,
		coll_x1=0, coll_x2=0,
		coll_y1=0, coll_y2=0,
		draw_coll=false,
		draw=function(self)
			spr(self.sprt,self.x,self.y)
		end,
		update=function(self)
			if self.tag=="ammo" then
				self.sprt=56
			elseif self.tag=="special" then
				self.sprt=57
			end
			self.coll_x1=self.x
			self.coll_x2=self.x+7
			self.coll_y1=self.y
			self.coll_y2=self.y+7
		end
	})
end
-- special attack -------------
special_is_on=false
special={
	ap_x=plr.x+15,ap_y=plr.y+10,
	sol_x=0, sol_y=0,
	sol_dx=0,sol_dy=0, ap_sprt=97,
	ap_sprt_first=97,
	ap_sprt_last=100,
	ap_open=false,
	sol_shot=false,
	anim_timr_val=2,
	anim_timr=2,
	ap_w=1, ap_h=2,
	sol_sprt=102,
	sol_sprt_first=102,
	sol_sprt_last=105,
	sol_sprt_atck=101,
	sol_flipx=false,
	sol_atck_timr_val=10,
	sol_atck_timr=10,
	tar_x=0, tar_y=0,
	mis_x=0, mis_y=0,
	mis_dx=0, mis_dy=0,
	mis_live=false,
	mis_col=1, mis_spd=0,
	draw=function(self)
		-- draw ramp
		spr(self.ap_sprt,
						self.ap_x, self.ap_y,
						self.ap_w, self.ap_h)
		-- draw soldier
		if self.ap_open then
			spr(self.sol_sprt,
							self.sol_x, self.sol_y,
							1,1, self.sol_flipx,false)
		end
		-- draw missile
		if self.mis_live then
			pset(self.mis_x,self.mis_y,
								self.mis_col)
			for i=0,3,1 do
				add_part(self.mis_x,
													self.mis_y,
													rnd(4)-2,
													rnd(5),1,2,1,1)
				add_part(self.mis_x,
													self.mis_y,
													rnd(4)-2,
													rnd(5),9,2,1,1)
			end
		end
	end,
	update=function(self)
		-- update ramp position
		self.ap_x=plr.coll_x2
		self.ap_y=plr.coll_y1-6
		-- set target
		for e in all(enemies) do
			if e.tag=="tank" then
				self.tar_x=e.cx
				self.tar_y=e.cy
				break
			else
				self.tar_x=flr(rnd(90)+10)
				self.tar_y=flr(rnd(60)+10)
				break
			end
		end
		-- open ramp
		if self.ap_sprt!=self.ap_sprt_last and
					self.sol_shot==false then
			if self.anim_timr<=0 then
				self.ap_sprt+=self.ap_w
				self.anim_timr=self.anim_timr_val
			else
				self.anim_timr-=1
			end
		end
		-- track if ramp is open
		if self.ap_sprt==self.ap_sprt_last then
			self.ap_open=true
		else
			self.sol_x=self.ap_x
			self.sol_y=self.ap_y+5
		end
		-- deploy soldier
		if self.ap_open then
			if plr.x<80 then
				-- move soldier right
				self.sol_flipx=false
				if self.sol_x<=self.ap_x+15 and
							self.sol_shot==false then
					self.sol_x+=1
				elseif self.sol_shot==false then
					self.sol_sprt=self.sol_sprt_atck
				end
				if self.sol_y<=self.ap_y+7 and
							self.sol_shot==false then
					self.sol_y+=1
				end
			else
				-- move soldier left
				self.sol_flipx=true
				if self.sol_x>=self.ap_x-35 and
							self.sol_shot==false then
					self.sol_x-=1
				elseif self.sol_shot==false then
					self.sol_sprt=self.sol_sprt_atck
				end
				if self.sol_y<=self.ap_y+7 and
							self.sol_shot==false then
					self.sol_y+=1
				end
			end
			-- update missile start pos
			if self.mis_live==false then
				self.mis_x=self.sol_x+5
				self.mis_y=self.sol_y-1
			end
			-- shoot missile
			if self.sol_sprt==self.sol_sprt_atck and
						self.mis_live==false and
						self.sol_shot==false then
				self.mis_live=true
				local diffx=self.tar_x-self.mis_x
				local diffy=self.tar_y-self.mis_y
				local dist=sqrt(diffx*diffx+diffy*diffy)
			 local normx=diffx/dist
				local normy=diffy/dist
				self.mis_dx=normx
				self.mis_dy=normy
				sfx(9,2)
			end
			-- update missile speed
			if self.mis_live then
				self.mis_spd+=0.1
			else
				self.mis_spd=0
			end
			-- update missle pos
			self.mis_x+=self.mis_dx*self.mis_spd
			self.mis_y+=self.mis_dy*self.mis_spd
			-- register hit
			if self.mis_y<self.tar_y then
				explode(self.mis_x,
												self.mis_y, 30)
				sfx(8,2)
				for i=0,30,1 do
					add_part(self.mis_x, self.mis_y,
														rnd(20)-10,rnd(20)-10,
														9, 3, 0.8,0.8)
					add_part(self.mis_x, self.mis_y,
														rnd(20)-10,rnd(20)-10,
														0, 3, 0.8,0.8)
				end
				self.mis_live=false
				self.sol_shot=true
				self.sol_sprt=self.sol_sprt_first
				for en in all(enemies) do
					if en.tag=="tank" then
						local diffx=en.cx-self.mis_x
						local diffy=en.cy-self.mis_y
						local dist=sqrt(diffx*diffx+diffy*diffy)
						if dist<30 then
							en.hp=0
						end
					end
				end
				for t in all(trees) do
					local diffx=t.x-self.mis_x
					local diffy=t.y-self.mis_y
					local dist=sqrt(diffx*diffx+diffy*diffy)
					if dist<30 then
						t.hp=0
					end
				end
			end
			-- get soldier back
			if self.sol_shot and
						self.mis_live==false then
				if plr.x<80 then
					-- move soldier left
					self.sol_flipx=true
					if self.sol_x>=self.ap_x-5 then
						self.sol_x-=1
					else
						self.ap_open=false
					end
					if self.sol_y>=self.ap_y+7 then
						self.sol_y-=1
					end
				else
					-- move soldier right
					self.sol_flipx=false
					if self.sol_x<=self.ap_x-5 then
						self.sol_x+=1
					else
						self.ap_open=false
					end
					if self.sol_y>=self.ap_y+7 then
						self.sol_y-=1
					end
				end
			end
			-- animate runnning
			if self.sol_sprt!=self.sol_sprt_atck then
				if self.anim_timr<=0 then
					if self.sol_sprt!=self.sol_sprt_last then
						self.sol_sprt+=1
					else
						self.sol_sprt=self.sol_sprt_first
					end
					self.anim_timr=self.anim_timr_val
				else
					self.anim_timr-=1
				end
			end
		end
		-- close ramp
		if self.ap_open==false and
					self.sol_shot then
			if self.ap_sprt!=self.ap_sprt_first then
				if self.anim_timr<=0 then
					self.ap_sprt-=self.ap_w
					self.anim_timr=self.anim_timr_val
				else
					self.anim_timr-=1
				end
			else
				special_is_on=false
				self.sol_shot=false
			end
		end
	end
}
-->8
-- enemies --
function enemies_init()
	enemy_timr_val=10
	enemy_timr=enemy_timr_val
	tank_timr_val=20
	tank_timr=tank_timr_val
	tank_track_timr_val=2
	tank_track_timr=0
	ids=0
end

enemies={}
function add_meat()
	add(enemies,{
		tag="meat", id=ids,
		x=flr(rnd(100)+10),	y=-8,
		dx=0,dy=0, scale=1,
		mov_timr_val=30,
		mov_timr=10,
		sprt_n=33, cx=0, cy=0,
		anim_timr=0,
		anim_timr_val=2,
		mov_ani_st=33,
		mov_ani_en=36,
		coll_x1=0, coll_x2=0,
		coll_y1=0, coll_y2=0,
		draw_coll=false,
		atck_timr_val=flr(rnd(300)+100),
		atck_timr=10,
			
		draw=function(self)
		 -- draw enemy --
			spr(self.sprt_n,
								self.x,
								self.y,
								self.scale,
								self.scale)
			--draw collider --
			if self.draw_coll then
				rect(self.coll_x1,
									self.coll_y1,
									self.coll_x2,
									self.coll_y2,8)
			end
		end,
			
		update=function(self)
			-- movement update --
			if self.mov_timr <= 0 then
				local numr=ceil(rnd(3))
				if numr != 3 then
					self.dx=rnd(1)-0.5
					self.dy=rnd(0.4)
				else
					self.dx=0
					self.dy=0
				end
				self.mov_timr=self.mov_timr_val
			end
			self.mov_timr-=1
				
			if self.dx > 0 or
						self.dy > 0 then
				if self.anim_timr<=0 then
						self.anim_timr=self.anim_timr_val
						if self.sprt_n==self.mov_ani_en then
							self.sprt_n=self.mov_ani_st
						else
							self.sprt_n+=1
						end
					else
						self.anim_timr-=1
					end
			else
				self.sprt_n=33
			end
			if self.x+self.dx > 10 and
			 		self.x+self.dx < 118 then
				self.x+=self.dx
			end
			self.y+=self.dy
			-- collider update --
			self.coll_x1=self.x+2
			self.coll_x2=self.x+6
			self.coll_y1=self.y+2
			self.coll_y2=self.y+6
			-- center point update --
			self.cx=self.coll_x1+(self.coll_x2-self.coll_x1)/2
			self.cy=self.coll_y1+(self.coll_y2-self.coll_y1)/2
			-- attack update --
			if self.atck_timr <= 0 then
				add_en_bull(self.x, self.y)
				self.atck_timr=self.atck_timr_val
			else
				self.atck_timr-=1
			end
		end
	})
end
-- add tank enemy -------------
function add_tank()
	add(enemies,{
		x=rnd({-8,128}), y=rnd(45)+2,
		dx=0, id=ids, tag="tank",
		sprt=42, scale=2, hp=100,
		tx=0,ty=0,tdy=0,cx=0,cy=0,
		t_sprt=15, t_sprt_h=2,
		rollin_timr=30, track_col=13,
		mov_timr=0, track_orig_col=13,
		track_blood_timr_val=10,
		track_blood_timr=10,
		mov_timr_val=100,
		atck_timr=100,
		atck_timr_val=100,
		anim_timr=0,
		anim_timr_val=2,
		coll_x1=0, coll_x2=0,
		coll_y1=0, coll_y2=0,
		draw_coll=false,
		
		draw=function(self)
			palt(0,false)
			palt(7,true)
			-- draw base --
			spr(self.sprt,
							self.x, self.y,
							self.scale, self.scale)
			-- draw turret --
			spr(self.t_sprt,
							self.tx, self.ty,
							1, self.t_sprt_h)
			-- draw collider --
			if self.draw_coll then
				rect(self.coll_x1,
									self.coll_y1,
									self.coll_x2,
									self.coll_y2, 8)
			end
			-- draw smoke --
			if self.hp<30 then
				for i=0,3,1 do
					add_part(self.x+8,
														self.y+10,
														rnd(4)-2,
														rnd(10)-10,
														0, 5, .4,.8)
				end
				for i=0,3,1 do
					add_part(self.x+8,
														self.y+10,
														rnd(4)-2,
														rnd(10)-10,
														6, 5, .4,.4)
				end
			end
			palt()
		end,
		
		update=function(self)
			-- death update --
			if self.hp<=0 then
				sfx(8,2)
				add_dest_tank(self.x,self.y,
																		self.tx,self.ty)
				for i=0,30,1 do
					add_part(self.x+8, self.y+10,
														rnd(20)-10,rnd(20)-10,
														9, 3, 0.8,0.8)
					add_part(self.x+8, self.y+10,
														rnd(20)-10,rnd(20)-10,
														0, 3, 0.8,0.8)
				end
				explode(self.cx,self.cy,30)
				en_killed+=5
				del(enemies, self)
			end
			-- moving in --
			if self.rollin_timr!=0 then
				if self.x < 63 then
					self.dx=1
					self.rollin_timr-=1
				else
					self.dx=-1
					self.rollin_timr-=1
				end
				self.x+=self.dx
			else
				-- moving --
				if self.mov_timr==0 then
					self.mov_timr=self.mov_timr_val
					if ceil(rnd(3))==3 then
						self.dx=rnd(2)-1
					else
						self.dx=0
					end
				else
					self.mov_timr-=1
				end
				-- screen constraints --
				if self.x+self.dx>-5 and
				self.x+self.dx<115 then
					self.x+=self.dx
				end
			end
			-- update turret placement --
			self.tx=self.x+4
			self.ty=(self.y+5)+self.tdy
			-- add tracks if moving --
			if self.dx > 0 then
				if tank_track_timr <= 0 then
					if self.track_col==self.track_orig_col then
						add_tracks(self.x+12,
																	self.y+8,
																	self.track_col)
						tank_track_timr=tank_track_timr_val
					else
						if self.track_blood_timr <= 0 then
							self.track_col=self.track_orig_col
							add_tracks(self.x+12,
																		self.y+8,
																		self.track_col)
							tank_track_timr=tank_track_timr_val
							self.track_blood_timr=self.track_blood_timr_val
						else
							add_tracks(self.x+12,
																		self.y+8,
																		self.track_col)
							tank_track_timr=tank_track_timr_val
							self.track_blood_timr-=1
						end
					end
				else
					tank_track_timr-=1
				end
			elseif self.dx < 0 then
				if tank_track_timr <= 0 then
					if self.track_col==self.track_orig_col then
						add_tracks(self.x+2,
																	self.y+8,
																	self.track_col)
						tank_track_timr=tank_track_timr_val
					else
						if self.track_blood_timr <= 0 then
							self.track_col=self.track_orig_col
							add_tracks(self.x+2,
																		self.y+8,
																		self.track_col)
							tank_track_timr=tank_track_timr_val
							self.track_blood_timr=self.track_blood_timr_val
						else
							add_tracks(self.x+2,
																		self.y+8,
																		self.track_col)
							tank_track_timr=tank_track_timr_val
							self.track_blood_timr-=1
						end
					end
				else
					tank_track_timr-=1
				end
			end
			-- moving sound --
			if self.dx!=0 then
				sfx(1,1,0,2)
			end
			-- update collider --
			self.coll_x1=self.x
			self.coll_x2=self.x+16
			self.coll_y1=self.y+8
			self.coll_y2=self.y+14
			-- center point update --
			self.cx=self.coll_x1+(self.coll_x2-self.coll_x1)/2
			self.cy=self.coll_y1+(self.coll_y2-self.coll_y1)/2
			-- attack update --
			if self.atck_timr <= 0 then
				if rnd(2)>1 then
					sfx(3,2)
					add_en_bull(self.x+8,
																self.y+24,
																self.tag)
					self.sprt+=32
					self.t_sprt=14
					self.tdy=-2
					for i=0,10,1 do
						add_part(self.x+8,
															self.y+18,
															rnd(5)-2.5,
															rnd(5)+1,
															9, 2, 0.5, 0.5)
						add_part(self.x+8,
															self.y+18,
															rnd(4)-2,
															rnd(3)+1,
															10, 2, 0.5, 0.5)
					end
				end
				self.atck_timr=self.atck_timr_val
			else
				self.atck_timr-=1
				self.t_sprt=15
				if self.sprt>46 then
					self.sprt-=32
				end
				if self.tdy<0 then
					self.tdy+=1
				end
			end
		end
	},1)
end

-- populate enemies --
function pop_enemies()
	if enemy_timr <= 0 and
	en_num > 0 then
		if tank_timr==0 then
			tank_timr=tank_timr_val
			if rnd(2) > 1 then
				add_tank()
				en_num-=1
				ids+=1
			end
		end
		add_meat()
		en_num-=1
		ids+=1
		tank_timr-=1
		enemy_timr=enemy_timr_val
	else
		enemy_timr-=1
	end	
end

-- bodies of dead enemies --
bodies={}
function add_body(_x,_y,_dx,_dy,_sp)
	add(bodies,{
		sprt=37,
		anim_timr_val=3,
		anim_timr=0,
		x=_x, y=_y, dx=_dx, dy=_dy,
		life=100,
		
		draw=function(self)
			spr(self.sprt,self.x,self.y)
		end,
		
		update=function(self)
		-- delete if old enough --
			if self.life <= 0 then
				del(bodies,self)
			else
				self.life-=1
			end
			-- inertia animation --
			if self.dy < 0 then
				self.y+=self.dy
				self.x+=self.dx
				self.dy*=_sp
				self.dx*=_sp
			end
			-- animation update --
			if self.sprt < 40 then
				if self.anim_timr > 0 then
					self.anim_timr-=1
				else
					self.sprt+=1
					self.anim_timr=self.anim_timr_val
				end
			end
		end
	})
end

dest_tanks={}
function add_dest_tank(_x,_y,_tx,_ty)
	add(dest_tanks,{
		x=_x, y=_y, tx=_tx, ty=_ty,
		dtx=rnd(30)-15, dty=rnd(30)-15,
		sprt=72, life=300, tsprt=13,
		draw=function(self)
			if self.life<=0 then
				del(dest_tanks, self)
			else
				palt(0,false)
				palt(7,true)
				spr(self.sprt,
								self.x, self.y,2,2)
				spr(self.tsprt,
								self.tx, self.ty,1,2)
				self.tx+=self.dtx
				self.ty+=self.dty
				self.dtx*=0.6
				self.dty*=0.6
				self.life-=1
				palt()
			end
		end
	})
end
-->8
-- environment --
function env_init(lvl)
	trees={}
	misc={}
	-- place trees --
	for i=0,flr(rnd(10)),1 do
		add_tree()
	end
	-- place trench and misc --
	for i=0,15,1 do
		add_misc(i*8,92,rnd({0,16,32}))
		add_misc(rnd(128),rnd(90),
											rnd({48,52,53,54}))
	end
end

function add_tree()
	add(trees, {
		x=flr(rnd(120)),
		y=flr(rnd(70)+10),
		hp=100,
		sprt=rnd({65,67,69}),
		sprt_s=2,
		coll_x1=0, coll_x2=0,
		coll_y1=0, coll_y2=0,
		draw_coll=false,
		
		draw=function(self)
			spr(self.sprt,
							self.x,
							self.y,
							self.sprt_s,
							self.sprt_s)
							
			if self.draw_coll then
				rect(self.coll_x1,
									self.coll_y1,
									self.coll_x2,
									self.coll_y2, 12)
			end
		end,
		
		update=function(self)
			if self.hp <= 0 then
				if self.sprt==65 then
					add_misc(self.x+4,
															self.y+8,
															64)
				elseif self.sprt==67 then
					add_misc(self.x-2,
															self.y+8,
															80)
				else
					add_misc(self.x+3,
															self.y+8,
															96)
				end
				del(trees, self)
			end
			self.coll_x1=self.x+2
			self.coll_x2=self.x+14
			self.coll_y1=self.y+2
			self.coll_y2=self.y+16
		end
	})
end

function add_misc(_x,_y,_sptr)
	add(misc,{
		x=_x, y=_y, sprt=_sptr,
		draw=function(self)
			spr(self.sprt,
							self.x,
							self.y)
		end
	})
end
-->8
-- scenes --

-- menue --
function menue_init()
	menu={
		back_col=6,
		frame_x1=2,
		frame_y1=2,
		frame_x2=125,
		frame_y2=125,
		frame_col=7,
		
		title_m2={
			mx=10, my=10, mspr=192,
			x2=26, y2=10, spr2=224
		},
		
		title_br={
			bx=10, by=30, bspr=249,
			rx=19, ry=30, rspr=250,
			ax=28, ay=30, aspr=251,
			dx=37, dy=30, dspr=252,
			lx=46, ly=30, lspr=253,
			ex=55, ey=30, espr=254,
			yx=64, yy=30, yspr=255
		},
		
		image={
			x1=64, y1=64, spr1=136,
			spr1_h=7, spr1_w=8,
			x2=48, y2=80, spr2=166,
			spr2_h=5, spr2_w=2
		},
		
		credits={
			x=10, y=40, col=13,
			text="by st | v1.0"
		},
		
		buttons={
			col_act=4,
			col_ina=1,
			start_x=10, start_y=84,
			start_act=true,
			start_col=4,
			exit_x=10, exit_y=94,
			exit_act=false,
			exit_col=1
		},
		
		draw=function(self)
			palt(0, true)
			palt(11,false)
			cls(self.back_col)
			-- draw title --
			-- text:m2
			spr(self.title_m2.mspr,
							self.title_m2.mx,
							self.title_m2.my,2,2)
			spr(self.title_m2.spr2,
							self.title_m2.x2,
							self.title_m2.y2,2,2)
			-- text:bradley
			spr(self.title_br.bspr,
							self.title_br.bx,
							self.title_br.by)
			spr(self.title_br.rspr,
							self.title_br.rx,
							self.title_br.ry)
			spr(self.title_br.aspr,
							self.title_br.ax,
							self.title_br.ay)
			spr(self.title_br.dspr,
							self.title_br.dx,
							self.title_br.dy)
			spr(self.title_br.lspr,
							self.title_br.lx,
							self.title_br.ly)
			spr(self.title_br.espr,
							self.title_br.ex,
							self.title_br.ey)
			spr(self.title_br.yspr,
							self.title_br.yx,
							self.title_br.yy)
							
			-- draw credits
			print(self.credits.text,
									self.credits.x,
									self.credits.y,
									self.credits.col)
							
			palt(0, false)
			palt(11,true)
			-- draw image --
			spr(self.image.spr1,
							self.image.x1,
							self.image.y1,
							self.image.spr1_w,
							self.image.spr1_h)
			spr(self.image.spr2,
							self.image.x2,
							self.image.y2,
							self.image.spr2_w,
							self.image.spr2_h)
							
			-- draw frame
			rect(self.frame_x1,
								self.frame_y1,
								self.frame_x2,
								self.frame_y2,
								self.frame_col)
								
			-- draw buttons
			print("start",
									self.buttons.start_x,
									self.buttons.start_y,
									self.buttons.start_col)
			print("exit",
									self.buttons.exit_x,
									self.buttons.exit_y,
									self.buttons.exit_col)
		end,
		
		update=function(self)
			if btn(2) and self.buttons.exit_act then
				self.buttons.exit_act=false
				self.buttons.start_act=true
				self.buttons.start_col=self.buttons.col_act
				self.buttons.exit_col=self.buttons.col_ina
			elseif btn(3) and self.buttons.start_act then
				self.buttons.start_act=false
				self.buttons.exit_act=true
				self.buttons.exit_col=self.buttons.col_act
				self.buttons.start_col=self.buttons.col_ina
			elseif btn(5) and self.buttons.start_act then
				start_level(level)
				current_scene="play"
				play=true
			elseif btn(5) and self.buttons.exit_act then
				cls(0)
				stop()
			end
		end
	}
end


__gfx__
00d0d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000777555777773337777733377
dd0d0ddd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000705155107031331070313310
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000751215157315131373151313
55555445000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000775555557399399373333333
45544444000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000777000257959995973500053
44444444000dddddddddddd0000dddddddddddd0000dddddddddddd0000d9aaaaaaaa9d0000d9aaaaaaaa9d0000d9aaaaaaaa9d077201020705a3a5070503050
4444454400d5dddddddd55dd00d5dddddddd55dd00d5dddddddd55dd00d5d999999995dd00d5d999999995dd00d5d999999995dd77051507779a3a9777053507
111111110d55dddddddd51d50d55dddddddd51d50d55dddddddd51d50d55dddddddd91d50d55dddddddd91d50d55dddddddd51d5777017777770307777703077
0000d000d555dddddddd51d5d555dddddddd51d5d555dddddddd51d5d555dddddddd51d5d555dddddddd51d5d555dddddddd51d5777717777770307777703077
dddd0ddd555d55dddddd55d5555d55dddddd55d5555d55dddddd55d5555d55dddddd55d5555d55dddddd55d5555d55dddddd55d5777711777777377777773777
0000000055ddddddddddddd555ddddddddddddd555ddddddddddddd555ddddddddddddd555ddddddddddddd555ddddddddddddd5777771777777377777773777
505555555d55555555cc555d5d55555555cc555d5d55555555cc555d5d55555555cc555d5d55555555cc555d5d55555555cc555d777771777777377777773777
44555455d155575555991115d155575555991115d155575555991115d155575555991115d155575555991115d155575555991115777717777777377777773777
44444445051111111111111505111111111111150511111111111115051111111111111505111111111111150511111111111115777777777777077777770777
44444444005151515151515000515151515151500051515151515150005151515151515000515151515151500051515151515150777777777777377777773777
11111111000555151515150000051555551515000005151515555500000555151515150000051555551515000005151515555500777777777779a97777777777
0000d000000000000003330000000000000333000003300003330000031808000112020000000000777777777777777777777777777777777777777777777777
dddd0ddd000333000003330000033300000333000033330003318000318000001122200000033300777777777777777777777777777777777777777777777777
00000000000333000001e100000333000001e100003e310003e818003ed802081d20000200033300777777777777771777777777777777177777777777777717
555555550001e100003111000001e100003111000031e8000388008031820000012100020001e10077777777777777d777777777777777d777777777777777d7
44555444003111000084d4d0003111000084d4d00001800000310000001100002211000000311100777777777777771777777777777777177777777777777717
444444440084d4d000013e000084d4d000013e00008488d00088880008022020020200000084d4d0777777777777771777777777777777177777777777777717
4444444400013e000000030000013e000003000000013e0000083e0d008218080000010200013e00777777777777771777777777777777177777777777777717
11111111000303000000030000030300000300000003030000300300300803001202001000030300777773333333331777777333333333177777733333333317
000000000000100000001000000000000000000000000000000000004fffff403fffff30cfffffc0773333310013130377333331001313037733333100131303
0000000000001000000010000d000000000000000000000000000000fff8fff0ff9f9ff0ff929ff0333513310013133333351331001313333335133100131333
00000000000010000000a000d0000000000005000000000000000000ff888ff0ff5f5ff0f92f29f0333513311113333333351331111333333335133111133333
00000000000d1d000009190000000000005005000550000000000000fff8fff0ff5f5ff0ff929ff0313111111111131331311111111113133131111111111313
00000000001ddd1000111110000000000050500000005500000050404fffff403fffff30cfffffc0313303330333031531330333033303153133033303330315
007707000555d11009aa111000000000077507000005005070055450114141101131311011c1c110715505550555051171550555055505117155055505550511
077777700555d5100555da10d00000007757007000500000007757704444444033333330ccccccc0771010101010101777101010101010177710101010101017
0000000005551500055515000d000000000000000000000000000077111111101111111011111110777111010101017777710111110101777771010101111177
00000000000000500000000000000000000000000000000000000000000000007777777777777777777777777777777777777777777777777777777777777777
00000000000005000005005000000000000000000005000000000000000000007777777777777777777777777777777777777777777777777777777777777777
00000000000505000005550000000000000000000015000000000000000000007777777777777777777777777777771777777777777777177777777777777717
0000000000005500001500000000000000000000005500000500000000000000777777777777777777777777777777d777777777777777d777777777777777d7
00000000000001000055000005000000000000000155000005005500000000007777777777777777777777777777771777777777777777177777777777777717
00005000000001500050000000500000000000005150000515005000000000007777777777777777777777777777771777777777777777177777777777777717
00015000000000500150000000505000000000000550000050005000000000007117777777777717777777777777771777777777777777177777777777777717
00015000000001500150000000050100000000000055000015055000000000001110777777752217777773333333331777777333333333177777733333333317
00000000000000105550000000051500500000000050000001550000000000001125507770151205773333310013130377333331001313037733333100131303
00000000000000555500000000051555100000000050150001150000000000001120150100151255333513310013139333351331001313933335133100131393
00000000000000015500000000015550510015000151500001500050000000001120155111155555333519311113993333351931111399333335193111139933
00000000000005015000000000015500055155500155000001500500000000007151111111111215319111a1111a1913319111a1111a1913319111a1111a1913
00000000000000555000000000155000005500050015500015555000000000007155055505550510313909aa0aaa0915313909aa0aaa0915313909aa0aaa0915
00010050000000015000000001555000000550000015500055000500000000007700000000000001715505550555051171550555055505117155055505550511
00015500000000015000000001550000000055000015500155000000000000007770101010177017771010101010101777101010101010177710101010101017
00155500000000015000000015550000000000500015500550000000000000001111110101010177777111010101017777710111110101777771010101111177
000000000000000000000000000000000000000000000d0000000000005550000000000000555000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000055520000555000005550000055500000555000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000555d0000555000001f100000555000001f1000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000555150001f100005515000001f100005515000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000051112c005515000dc2d2dd005515000dc2d2dd0000000000000000000000000000000000000000000111110
150000000000000000000000000000000000000005555d00dc2d2dd00015f000dc2d2dd00015f000000000000000000000000000000000000000000111111111
15500150d0000000000d0000000000000000000000551d000015f000055050000015f00000555000000000000000000000000000000000000000000111112211
15500550500000000055000000000000000000000000500000505000000005000005500000550000000000000000000000000000000000000111011111112115
00001000500000000550000000005d5000000000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb00000000000000000000000000000000000000001551111111111215
0000100050000000555000005555555050000000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb00000000000000000000000000000000000000005151221111111155
0000200050000000555000005555555055550000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb00000000000000000000000000000000000000005511111111111115
00021200d0000000550000005555555055555d00bbbbbbbbb4bbb4bbbbbb4bbbbbbbbbbb00000000000000000000000000000000000000005155111112c55551
00111110500000005100000055111d0055555550b4bbb4bbbb41944bbbbb44bbbbbbbbbb00000000000000000000000000000000000000001155171121591115
0222111050000000100000001110000015555550bb41944bbb4004bbb4b19bbbbbbbbbbb00000000000000000000000000000000000000000011111111111115
0111d21000000000000000000000000001115550bb4004bbb4bbbb4bbb4104bbbbb45bbb00000000000000000000000000000000000000000001515151515150
0551150000000000000000000000000000001d10bb4bb4bbbbbbbbbbbbb4b4bbbb5444bb00000000000000000000000000000000000000005555551515151500
bbbbbbbbb111111111bbbbbbbbbbbbbb00000000000000000000000060000006bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb55551bbbbbbb
bbbbbbb55555500001111bbbbbbbbbbb00000000000000000000000006000060bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb555511bbbbb55551bbbbbbb
bbbbbb5555000000000000bbbbbbbbbb00000000000000000000000000600600bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb55dd511bbbbb555511bbbbbb
bbbb1555500000055555500bbbbbbbbb00000000000000000000000000066000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb55dd511bbbb5555111bbbbbb
bbb155550000555555555551bbbbbbbb00000000000000000000000000066000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb55dd511555555551115555bb
bbb155500005555d5dd511111bbbbbbb00000000000000000000000000600600bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbddd1111110000555511155555b
bb1155010055dd111111111110bbbbbb00000000000000000000000006000060bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb5555555555555555515555111111
bb155510055111111144f444100bbbbb00000000000000000000000060000006bbbbbbbbbbbbbbbbbbbbbbbbbbbbb55111155555555555555555105555111111
bb155010551114ff449ffff44900bbbb00000000000000000000000060000006bbbbbbbbbbbbbbbbbbbbbbbbbbb555115551100055dddd5d5551015555111111
bb111000514499fff49fffff99999bbb00000000000000000000000006000060bbbbbbbbbbbbbbbbbbbbbbbbbb55511500511005555555555510105555111111
bb00100551499ffff99ff11f9999bbbb00000000000000000000000000600600bbbbbbbbbbbbbbbbd1dddddddddd1dd110051055dddd5d555111015555111111
bb00010011999ff11f9f1111f500bbbb00000000000000000000000000066000bbbbbbbbbbbbbbbbbbbbbbbb5500001110001555555555551110105555111111
b00000001499f111119ffffff500bbbb00000000000000000000000000066000bbbbbbbbbbbbbbbbbbbbbbbb5555515500015555555555511111015555111111
b010000009ffffffff9ff111f500bbbb00000000000000000000000000600600bbbbbbbbbbbbbbbbbbbbbbbb5551111111105111111115111110105555111111
b00100d00fffd1111f9ff7071100bbbb00000000000000000000000006000060bbbbbbbbbbbbbbbbbbbbbbbbbb11111111110511111111511111015555111111
b00000100ff117007ffff7ddd000bbbb00000000000000000000000060000006bbbbbbbbbbbbbbbbbbbbbbbbbbbddd1111110511111111515110105511111111
b00100100ffff7dddfffff77000bbbbb0000000000000000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb55555555d5111555500051111111115555111111111111
b00100000ffff077fffffffdfd0bbbbb0000000000000000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb5555555555d5111555111151000000115555555511111115
bb0d00d00fffdfdffffffdfff1bbbbbb0000000000000000bbbbbbbbbbbbbbbbbbbbbbbbbb5555555111111111d5111110000100000000005555555551111115
bbb000d00fffffffffffdffff19bbbbb0000000000000000bbbbbbbddddd11bbbbbbbb5555555555555555555115555555555555555011115555555551111155
bbbbb00001fffff222fffffff149bbbb0000000000000000bbbbbbd1220111bb55dd55d55dd5dddddd5ddd511ddddddd11555555115055555551111111111155
bbbb1166111fff27772ffffff1499bbb0000000000000000bbbbbbd1980111b5555555555555555555555515d111122111555551155555555555111111111155
b11111110011ffeeeee22fff14449bbb0000000000000000bbbbbbd10dd11155555555555555555555555155d155198111555511511111111111111111111555
111ffff100011ffeeeeee2f111bb9bbb0000000000000000bbbbbbbd0dd5115d155d155d155d15555d151555d15dd00111555115155555555555555555555555
11ffffff01d6011ffeeeff11001bbbbb0000000000000000bbbbbbbd155111515551555155515555515155555d5dd10511551151111111111111111111115555
1ddfffffd01d6dd00fff00000001bbbb0000000000000000bbbbbbbd155515555555555555555555551555555d15510511511511111111111111555555555555
1dddffffd00dd0000000055555001bbb0000000000000000bbbbbbb555555d155d155d155d1555d1515555555d15555515115111555555555555111111111111
0dddfddfdf0000000005511555501bbb0000000000000000bbbbbb55555555555555555555555555155555555555555551151115155555555511111111111111
00dddfdf0f10000055551cc1555551bb0000000000000000bbbbbb11111111111111111111111111555555555555555511511151511111111111111111111111
1000dd0f00000055155199cc155551bb0000000000000000bbbbbbb1111111111111111111111111111111111111111115111515111111111111116666666611
00000d0d00000555515519915155511b0000000000000000bbbbbbb5555555555555111111111115111111111111111151115151111000111111111661166611
0000000d00555555555551115515551b0000000000000000bbbbbb55555555555555555555555555511111111111111555151511111000111111116661166611
000000000000000000000000000000000000000000000000bbbbb555111555555555555555555555555555555555555555515111111010111111116661166611
000000000000000000000000000000000000000000000000bbbb5555555155555555555555555555555555555555555555151111111011111111116111111611
011000000000011000000000000000000000000000000000bbb55555555155555555555555555555555555511115511515511111111111111111116111111611
1dd1000000001dd100000000000000000000000000000000bbb55555551111110010115555555555555555155555555555511111111111110111116661166611
1ddd10000001ddd100000000000000000000000000000000bb555555551111001111110000010111555551555555555551511111111111111111116661166611
1dddd100001dddd100000000000000000000000000000000bb555555511110111111111111111111110001555555555511151111111111111111116661666611
1ddddd1001ddddd100000000000000000000000000000000bbbb0000000011115511111111111111111155555555555111151111111111110111116666111111
1dd1ddd1021dddd100000000000000000000000000000000bbbb1010101555555050111111111111111155555555551111115111111111111111111111111111
1dd11ddd10211dd100000000000000000000000000000000bbbb1101015555550051010101011101111555555555511111115111111111110111111111111111
1dd121ddd1021dd100000000000000000000000000000000bbbbb110105555500100101010101010105155555555511111111511111111110111111111155555
1dd1021dd1021dd100000000000000000000000000000000bbbbb111115555501011010101010101015111000000511111111511111111110111115555500000
1dd1002112021dd100000000000000000000000000000000bbbbbb11111555500101101010101010105111010100000000001151111111115555555500001050
1dd1000220021dd100000000000000000000000000000000bbbbbbb1111155551111010101010101015111501010110100000151115555550000000005001550
1dd1000000021dd100000000000000000000000000000000bbbbbbbbb11115555110001010101010101111551101011100000055555000000050010500001550
1dd1000000021dd100000000000000000000000000000000bbbbbbbbbb1111155510000001010101010111151111111000000051000001050000015505001550
211000000000211000000000000000000000000000000000bbbbbbbbbbb111111001000000000000101011151111111110000510050001550050015505011500
000000000000000000000000000000000000000000000000bbbbbbbbbbbbb1111100000000000000bbbbb1100111111110155101005001550050015505115500
000000000000000000000000000000000000000000000000bbbbbbbbbbbbbb111110000000000bbbbbbbbb110011111111100010050001550050115500555500
000111111111100000000000000000000000000000000000bbbbbbbbbbbbbbbb1111000bbbbbbbbbbbbbbbbb1001111111110001055011550055155500055111
001ddddddddd110000000000000000000000000000000000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb111111111000055115550005555500111bbb
01dddd11111dd11000000000000000000000000000000000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb11111111100005555500000555011bbbbbb
01111122221ddd1000000000000000000000000000000000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb1111111100005555000001111bbbbbbbb
02222200001ddd1000000000000000000000000000000000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb1111111100055001111bbbbbbbbbbbb
00000000001ddd1000000000000000000000000000000000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb1111111111111bbbbbbbbbbbbbbbb
00011111111ddd100000000000000000000000000000000000000000600000060000000011011110111110100001100011011000112000001101111111000011
0011dddddddddd100000000000000000000000000000000000000000060000600000000011021111111110110001100011011110112000001101111211000011
011dd111111111100000000000000000000000000000000000000000006006000000000011000111111220110011110011021111112000001102222021100112
01ddd122222222200000000000000000000000000000000000000000000660000000000011011112111000110011110011002211112000001111100001100110
01ddd100000000000000000000000000000000000000000000000000000660000000000011011110111111120112211011000011112000001111100002110210
01ddd111111111100000000000000000000000000000000000000000006006000000000011022111111111200110011011001111112000001122200000111020
01dddddddddddd100000000000000000000000000000000000000000060000600000000011000111111211101111121111111112111111101111111000211000
01111111111111100000000000000000000000000000000000000000600000060000000011011112111001111122201111111220111111111111111100011000
__map__
00000000000000000000000000000000f7000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000f7000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000c0c1c2c300000000000000000000f7000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000d0d1d2d300000000000000000000f7000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000f9fafbfcfdfeff00000000000000f7000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000f7000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000f7000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000f7000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000088898a8b8c8d8e8ff7000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000098999a9b9c9d9e9ff7000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000a6a7a8a9aaabacadaeaff7000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000b6b7b8b9babbbcbdbebff7000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000c6c7c8c9cacbcccdcecff7000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000d6d7d8d9dadbdcdddedff7000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000e7e8e9eaebecedeeeff7000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000f7000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000000000374004750057400563003620016100071000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000100020361008610006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600
000900000061000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000400002e63028630226301d6301962016620126200f6200c6200a62008620066200562004620036100261000610006100000000000000000000000000000000000000000000000000000000000000000000000
00010000110101401019010340103201013010110100f0100d0100b01008010080100151001500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0001000005110071100a1100e110101102e110291100e1100b1100411003110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00020000056100e5101c71027610326100a6100161002610000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00020000086102e610224101941016410154100561008610036100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0004000002120021202c63034640386403b6503d6503d6503a640386403663034630326202f6202b6202662024620226201e6101c6101a6101761014610106100d6100a610086100661004610036100161000610
0004000002610026100261003610036200462004620056200562006620066200762008620096200a6200a6200b6200c6200e6200f62010620116201362013620146201562016620186301a6301b6301d6401f640
00060000047501f5502855019400080001b0001d0000b0000d0002400011000160001700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000600000a55020050280500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000600000b5202732018540035000a6000d6000660001600186000a6000a600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
