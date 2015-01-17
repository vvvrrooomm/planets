require 'rubygems'
require 'bundler/setup'
require 'glfw3'
require 'opengl'
require 'thread'

require 'gl'
require 'glu'
require 'glut'
require 'matrix'

include Gl
include Glu
include Glut

require './planets.rb'

################ simulator ###########################

def simulateOneStep(delta_t)
  orbitals = $orbitals.inject({}){|res, (name, orbital)| res[name]=planetHelioEquatorialOn(orbital, name, delta_t); res[name][:size]=orbital[:size]; res }

end

################## drawing ############################

def drawSphere(pos_x, pos_y, pos_z, color, size)
  no_mat = [ 0.0, 0.0, 0.0, 1.0 ]
  mat_ambient = [ 0.7, 0.7, 0.7, 1.0 ]
  mat_ambient_color = [ 0.8, 0.8, 0.2, 1.0 ]
  mat_diffuse = [ 0.1, 0.5, 0.8, 1.0 ]
  mat_specular = [ 0.10, 0.10, 0.10, 1.0 ]
  no_shininess = [ 0.0 ]
  low_shininess = [ 5.0 ]
  high_shininess = [ 100.0 ]
  mat_emission = [0.3, 0.2, 0.2, 0.0]

  colors = {
    sun: [ 1.0, 0.75, 0.0, 1.0],
    mercury: [ 0.94, 0.97, 1.0, 1.0],
    venus: [ 0.91, 0.84, 0.42, 1.0],
    mars: [ 1.0, 0.0, 0.0, 1.0],
    jupiter: [ 0.56, 0.59, 0.47, 1.0],
    saturn: [ 1.0, 0.6, 0.40, 1.0],
    uranus: [ 0.0, 1.0, 1.0, 1.0],
    neptune: [ 1.0, 0.50, 1.0, 1.0],
  }
    
  
  glPushMatrix()
  glTranslate(pos_x, pos_y, 0)
  glMaterial(GL_FRONT, GL_AMBIENT, colors[color])
  glMaterial(GL_FRONT, GL_DIFFUSE, mat_diffuse)
  glMaterial(GL_FRONT, GL_SPECULAR, mat_specular)
  glMaterial(GL_FRONT, GL_SHININESS, high_shininess)
  glMaterial(GL_FRONT, GL_EMISSION, no_mat)
  glutSolidSphere(1, 106, 106)
  glPopMatrix()
end


def drawNewState(window,state)
  w, h = window.framebuffer_size()
  Gl.glViewport(0, 0, w, h)
  glClearColor(0.0,0.0,0.0,0.0)
  
  glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
  
  state.each do |name, pos|
    #puts "#{name} "
    #pos.each{|key, val| puts"#{key}:#{val}"}
    #    drawTriangle(xh,yh,zh, name)
    drawSphere(pos[:xh],pos[:yh],pos[:zh], name, pos[:size])
  end
end

HOME = [0.0, 0.0, 50.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0]
@frustum = HOME
@rotated=false
def cameraRotate(dir)
  case dir
  when :reset
    glPopMatrix if @rotated
    @rotated=false
  when :up
    glPushMatrix if not @rotated
    @rotated = true
    glRotatef(1, 0.0,50.0,0.0,)
  when :down
    glPushMatrix if not @rotated
    @rotated = true
    glRotatef(-1, 0.0,50.0,0.0,)
  when :left
    glPushMatrix if not @rotated
    @rotated = true
    glRotatef(1, 0.0,0.0,50.0,)
  when :right
    glPushMatrix if not @rotated
    @rotated = true
    glRotatef(-1, 0.0,0.0,50.0,)
  end
end

def reshape(window, width, height)
  w, h = window.framebuffer_size()

  glShadeModel(GL_FLAT)

  Gl.glViewport(0, 0, w, h)
  Gl.glMatrixMode(GL_PROJECTION)
  Gl.glLoadIdentity()

  gluPerspective(60.0,  width.to_f/height.to_f, 1.0, 100.0)
  Gl.glMatrixMode(GL_MODELVIEW )
  Gl.glLoadIdentity()
  gluLookAt(*@frustum)

  ambient = [ 0.0, 0.0, 0.0, 1.0 ]
  diffuse = [ 1.0, 1.0, 1.0, 1.0 ]
  position = [ 0.0, 0.0, 50.0, 0.0 ]
  lmodel_ambient = [ 0.4, 0.4, 0.4, 1.0 ]
  local_view = [ 0.0 ]

  glEnable(GL_DEPTH_TEST)
  glDepthFunc(GL_LESS)

  glLight(GL_LIGHT0, GL_AMBIENT, ambient)
  glLight(GL_LIGHT0, GL_DIFFUSE, diffuse)
  glLight(GL_LIGHT0, GL_POSITION, position)
  glLightModel(GL_LIGHT_MODEL_AMBIENT, lmodel_ambient)
  glLightModel(GL_LIGHT_MODEL_LOCAL_VIEWER, local_view)

  glEnable(GL_LIGHTING)
  glEnable(GL_LIGHT0)

  glClearColor(0.0, 0.1, 0.1, 0.0)
  glClearColor(0.0,0.0,0.0,0.0)
  glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
end

################# system stuff #################################

def handleKeys(keyQueue)
  while not keyQueue.empty?
    key = keyQueue.shift
    case  key
    when Glfw::KEY_HOME
      cameraRotate(:reset)
    when Glfw::KEY_UP
      cameraRotate(:up)
    when Glfw::KEY_DOWN
      cameraRotate(:DOWN)
    when Glfw::KEY_LEFT
      cameraRotate(:LEFT)
    when Glfw::KEY_RIGHT
      cameraRotate(:right)
    when  Glfw::KEY_KP_ADD, Glfw::KEY_RIGHT_BRACKET
      cameraRotate(:zoomIn)
    when Glfw::KEY_MINUS, Glfw::KEY_SLASH, Glfw::KEY_KP_SUBTRACT
      cameraRotate(:zoomOut)
    when Glfw::KEY_ESCAPE
    else
      puts "unknown key pressed #{key}"
    end
  end
end


def eventLoop(window, keyQueue)
  delta_t=1
  loop do
    Glfw.poll_events
    handleKeys(keyQueue)
    state = simulateOneStep(delta_t)
    drawNewState(window, state)

    delta_t += 1
    window.swap_buffers
    break if window.should_close?
  end
end

def main
  Glfw.init
  glutInit

  window = Glfw::Window.new(800, 600, "Planets")
  keyQueue = []# Queue.new
  
  # Set some callbacks
  window.set_key_callback do |window, key, code, action, mods|
    window.should_close = true if key == Glfw::KEY_ESCAPE
    keyQueue.push(key) if action == Glfw::REPEAT or action == Glfw::PRESS
  end

  window.set_close_callback do |window|
    window.should_close = true
  end

  window.make_context_current
  reshape(window, window.size[0], window.size[1])

  eventLoop(window, keyQueue)

  # Explicitly destroy the window when done with it.
  window.destroy
end


if $0 == __FILE__
  main
end
