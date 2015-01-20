require 'rubygems'
require 'bundler/setup'
require 'glfw3'
require 'opengl'
require 'thread'
require 'oily_png'

require 'gl'
require 'glu'
require 'glut'
require 'matrix'

include Gl
include Glu
include Glut

require_relative 'planets_kepler'
require_relative 'planets_relativistic'
require_relative 'assets'

class Renderer
  include Assets
  
  @drawPath
  @simulator
  @planets

  
  ################ simulator ###########################
  def simulateOneStep(delta_t)
    state={}
    state[:orbitals] = @simulator.simulateOneStep(delta_t)
    state[:paths] = @simulator.getPaths if @drawPath
#    puts state[:orbitals][:earth].inspect
    return state
  end

  def simulatorInit
    @simulator = PlanetsRelativistic.new
    @drawPath = true
    @simulationPaused = true
    @step = 0
  end
  ################## drawing ############################

  @@colors = {
      sun: [ 1.0, 0.75, 0.0, 1.0],
      mercury: [ 0.94, 0.97, 1.0, 1.0],
      venus: [ 0.91, 0.84, 0.42, 1.0],
      mars: [ 1.0, 0.0, 0.0, 1.0],
      jupiter: [ 0.56, 0.59, 0.47, 1.0],
      saturn: [ 1.0, 0.6, 0.40, 1.0],
      uranus: [ 0.0, 1.0, 1.0, 1.0],
      neptune: [ 1.0, 0.50, 1.0, 1.0],
      earth: [ 0.91, 0.84, 0.42, 1.0],
      moon:[ 0.94, 0.97, 1.0, 1.0],
      pluto:  [ 1.0, 0.6, 0.40, 1.0],
    }

  HOME = [0.0, 0.0, -50.0]
  Nullvector = [0.0, 0.0, 0.0]

  def createSphere( size)
    sphere = gluNewQuadric();
    gluQuadricDrawStyle(sphere, GLU_FILL);
    gluQuadricTexture(sphere, TRUE);
    gluQuadricNormals(sphere, GLU_SMOOTH);

    axis = gluNewQuadric();
    gluQuadricTexture(axis, TRUE);
    #Making a display list
    list = glGenLists(1);
    glNewList(list, GL_COMPILE);
    gluSphere(sphere, size/50000.to_f, 106, 106);

    axisRad = size/50000.to_f * 0.05
    axisLen = size*2/50000.to_f*1.20
    glTranslate(0, 0, -axisLen/2)
    glBindTexture(GL_TEXTURE_2D, @planets[:polarAxis])
    gluCylinder(axis, axisRad, axisRad, axisLen, 32,32);
    glEndList();
    gluDeleteQuadric(axis)
    gluDeleteQuadric(sphere);
    return list
  end

    #gl_Position = projection * camera * model * vec4(vert, 1);# evaluate from RtoL
  
  def drawSphere(data, name)
    no_mat = [ 0.0, 0.0, 0.0, 1.0 ]
    mat_ambient = [ 0.7, 0.7, 0.7, 1.0 ]
    mat_ambient_color = [ 0.8, 0.8, 0.2, 1.0 ]
    mat_diffuse = [ 0.1, 0.5, 0.8, 1.0 ]
    mat_specular = [ 0.10, 0.10, 0.10, 1.0 ]
    no_shininess = [ 0.0 ]
    low_shininess = [ 5.0 ]
    high_shininess = [ 100.0 ]
    mat_emission = [0.3, 0.2, 0.2, 0.0]

    glBindTexture(GL_TEXTURE_2D, @planets[name])
    glPushMatrix()
    @spheres[name] = createSphere( data[:size]) unless @spheres.has_key?(name)

    glTranslate(*data[:pos])

    glRotatef(data[:obl], 0, 1, 0) #tilt of planets axis
    glRotatef(data[:rot], 0, 0, 1) #planet's revolution
    glCallList(@spheres[name])    
    glPopMatrix()
    
  end

  def drawPath(path)
    color = @@colors[path[0]]
    glBegin GL_LINES
    glColor4f(*color)
    path[1].each do |point|
      glVertex3f(*point)
    end
    glEnd
  end
    
  
  def drawNewState(window,state)
    w, h = window.framebuffer_size()
    Gl.glViewport(0, 0, w, h)
    glClearColor(0.0,0.0,0.0,0.0)
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    glPushMatrix
    glLoadIdentity()
#camera matrix
      glTranslate(*@cameraTrans)
      glRotatef(-@cameraRot[2], 0.0, 0.0, 1.0)
      glRotatef(-@cameraRot[1], 0.0, 1.0, 0.0)
      glRotatef(-@cameraRot[0], 1.0, 0.0, 0.0)
      if not @follow.nil?
        follow = -1 *state[:orbitals][@follow][:pos] 
      glTranslate(*follow)
    end
    
#object matrix done in render function
    state.each do |name, data|
      case name
      when :orbitals
        data.each{|name,pos| drawSphere(pos, name) }
      when :paths
        data.each{|el| drawPath(el)} unless data.nil?
      end
    end
    glPopMatrix
  end
  
  def cameraRotate(dir)
    case dir
    when :reset
      @cameraRot.replace Nullvector
      @cameraTrans.replace HOME
    when :up
      @cameraRot[0]+=1
      @cameraRot[0] = 0 if @cameraRot[0] > 360
    when :down
      @cameraRot[0]-=1
      @cameraRot[0] = 360 if @cameraRot[0] < 0
    when :left
      @cameraRot[1]+=1
      @cameraRot[1] = 0 if @cameraRot[1] > 360
    when :right
      @cameraRot[1]-=1
      @cameraRot[1] = 360 if @cameraRot[1] < 0
    when :zoomIn
      @cameraTrans[2] += 1
    when :zoomOut
      @cameraTrans[2] -= 1
    else
      puts "unknown rotation #{dir}"
    end
  end

  def reshape(window, width, height)
    w, h = window.framebuffer_size()

    glShadeModel(GL_FLAT)

    glViewport(0, 0, w, h)
    glMatrixMode(GL_PROJECTION)
    glLoadIdentity()
    gluPerspective(60.0,  width.to_f/height.to_f, 1.0, 100.0)

    ambient = [ 0.5, 0.5, 0.5, 1.0 ]
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

    glClearColor(0.0,0.0,0.0,0.0)
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

    glMatrixMode(GL_MODELVIEW )
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
        cameraRotate(:down)
      when Glfw::KEY_LEFT
        cameraRotate(:left)
      when Glfw::KEY_RIGHT
        cameraRotate(:right)
      when  Glfw::KEY_KP_ADD, Glfw::KEY_RIGHT_BRACKET
        cameraRotate(:zoomIn)
      when Glfw::KEY_MINUS, Glfw::KEY_SLASH, Glfw::KEY_KP_SUBTRACT
        cameraRotate(:zoomOut)
      when Glfw::KEY_R
        @follow = :mercury
      when Glfw::KEY_V
        @follow = :venus
      when Glfw::KEY_E
        @follow = :earth
      when Glfw::KEY_M
        @follow = :mars
      when Glfw::KEY_J
        @follow = :jupiter
      when Glfw::KEY_S
        @follow = :saturn
      when Glfw::KEY_U
        @follow = :uranus
      when Glfw::KEY_N
        @follow = :neptune
      when Glfw::KEY_P
        @follow = :pluto
      when Glfw::KEY_BACKSPACE
        @follow = nil
      when Glfw::KEY_P
        @drawPath = !@drawPath
      when Glfw::KEY_ENTER
        @simulationPaused = !@simulationPaused
      when Glfw::KEY_SPACE
        @step += 1
      when Glfw::KEY_ESCAPE
      #empty to suppress unknown key message
      else
        puts "unknown key pressed #{key}"
      end
    end
  end


  def eventLoop(window, keyQueue)
    delta_t = 1
    state = simulateOneStep(delta_t) 
    loop do
      Glfw.poll_events
      handleKeys(keyQueue)

      
      state = simulateOneStep(delta_t) unless @simulationPaused and @step == 0
      @step -= 1 if @step > 0
      drawNewState(window, state)
      window.swap_buffers
        
      break if window.should_close?
    end
  end

  def loadTexture(name)
    ChunkyPNG::Image.from_file('data/'+TEXTURES[name])
  end
  
  def initTextures
    @planets = {}
    puts "max textures: #{GL_MAX_COMBINED_TEXTURE_IMAGE_UNITS}"
    
    planets = @simulator.getPlanetList
    planets.push(:polarAxis)
    textureIds = glGenTextures(planets.length)
    planets.each do |name|
      @planets[name] = textureIds.shift
      print "loading texture #{name}, id #{@planets[name]} .."
      image = loadTexture(name)
      print " upload .."
      glBindTexture(GL_TEXTURE_2D, @planets[name])
      glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT)
      glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT)
      glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR)
      glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR)
      glTexEnvf(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE)
      glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, image.width, image.height, 0, GL_RGBA, GL_UNSIGNED_BYTE, image.to_rgba_stream)
      #print " mipmap .."
      # And create 2d mipmaps for the minifying function
      #gluBuild2DMipmaps(GL_TEXTURE_2D, GL_RGBA, image.width, image.height, GL_RGBA, GL_UNSIGNED_BYTE, image.to_rgba_stream)
      puts " done"
    end

    glEnable(GL_TEXTURE_2D) 
  end
  
  def initialize
    Glfw.init
    glutInit

    window = Glfw::Window.new(800, 600, "Planets")
    keyQueue = []

    # Set some callbacks
    window.set_key_callback do |window, key, code, action, mods|
      window.should_close = true if key == Glfw::KEY_ESCAPE
      keyQueue.push(key) if action == Glfw::REPEAT or action == Glfw::PRESS
    end

    window.set_close_callback do |window|
      window.should_close = true
    end

    simulatorInit

    @spheres = {}
    @cameraRot = []
    @cameraRot.replace Nullvector
    @cameraTrans = []
    @cameraTrans.replace HOME
    window.make_context_current

    initTextures

    reshape(window, window.size[0], window.size[1])

    eventLoop(window, keyQueue)

    # Explicitly destroy the window when done with it.
    window.destroy
  end

end

if $0 == __FILE__
  manager = Renderer.new

end
