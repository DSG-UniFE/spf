require 'resolv'
require 'shoes'

Shoes.app title: "Client", resizable: true, width: 650, height: 600 do
  background gainsboro
  para_width = 140
  line_width = 100
  para_margin = [10, 8, 10, 0]

  @data = {}
  RADIUS = 3000
  METERS_IN_DEGREE = 111_300

  stack do
    flow do
      para strong("IP:"), width: para_width, margin: para_margin
      @data[:ip] = edit_line "127.0.0.1"
      para strong("Port:"), width: 120, margin: [30, 8, 10, 0]
      @data[:port] = edit_line "52161"
    end
    flow do
      para strong("Application:"), margin: para_margin, width: para_width
      @data[:app] = edit_line "surveillance/basic"
    end
    flow do
      para strong("Service:"), width: para_width, margin: para_margin
      @data[:service] = edit_line "count objects"
    end
    flow do
      para strong("User:"), width: para_width, margin: para_margin
      @data[:user] = edit_line "3"
    end
    stack do
      para strong("Request:"), width: para_width, margin: para_margin
      @data[:request] = {}
      flow margin: [16, 5, 10, 0] do
        @data[:request][:single] = radio :request
        @data[:request][:single].checked = true
        @data[:request][:single].click do
          if @data[:request][:single].checked?
            @data[:timer].text = ""
            @data[:request][:multiple].checked = false
          end
        end
        para "Single"
      end
      flow margin: [16, 5, 10, 0] do
        @data[:request][:multiple] = radio :request
        @data[:request][:multiple].click do
          if @data[:request][:multiple].checked?
            @data[:timer].text = "5"
            @data[:request][:single].checked = false
          end
        end
        para "Multiple", width: para_width
        para "Timer:", width: 100
        @data[:timer] = edit_line
      end
    end
    stack do
      flow do
        para strong("Geolocation:"), width: 170, margin: para_margin
        @randomness = check; para "Randomness", margin_left: 5 #, margin_right: 10

      end
      flow margin: [20, 5, 10, 0] do
        para "Latitude:", width: para_width
        @data[:lat] = edit_line "44.838124"
      end
      flow margin: [20, 5, 10, 0] do
        para "Longitude:", width: para_width
        @data[:lon] = edit_line "11.619786"
      end
    end
  end

  stack margin: 10 do
    flow do
      @btn_request = button "Send request"
      @btn_request.click do
        @count = 1
        @console.replace(">>")
        validate = true
        unless check_ip? @data[:ip].text
          alert "Incorrect IP"
          validate = false
        end
        unless check_port? @data[:port].text
          alert "Incorrect port"
          validate = false
        end
        unless check_request? @data[:request], @data[:timer].text
          alert "Incorrect request, select 'Single' or 'Multiple'"
          validate = false
        end
        unless check_latitude? @data[:lat].text
          alert "Incorrect latitude"
          validate = false
        end
        unless check_longitude? @data[:lon].text
          alert "Incorrect longitude"
          validate = false
        end
        # app.info "IP: " + @data[:ip].text
        # app.info "Port: " + @data[:port].text
        # app.info "Application: " + @data[:app].text
        # app.info "Service: " + @data[:service].text
        # app.info "User: " + @data[:user].text
        # app.info "Single request " + @data[:request][:single].checked?.to_s
        # app.info "Multiple request " + @data[:request][:multiple].checked?.to_s + \
        #   ", timer: " + @data[:timer].text
        # app.info "Latitude: " + @data[:lat].text
        # app.info "Longitude: " + @data[:lon].text
        if validate
          if @randomness.checked?
            @data[:lat].text, @data[:lon].text = randomLocation(
                @data[:lat].text.to_f,
                @data[:lon].text.to_f,
                RADIUS)
          end
          send_request @data
        end
        if validate and @data[:request][:multiple].checked?
          @btn_stop_timer.show
          @timer = every(@data[:timer].text.to_i.round) do
            # app.info "Sent request"
            @count += 1
            if @randomness.checked?
              @data[:lat].text, @data[:lon].text = randomLocation(
                  @data[:lat].text.to_f,
                  @data[:lon].text.to_f,
                  RADIUS)
            end
            send_request @data
          end
        end
      end

      @btn_stop_timer = button "Stop timer", margin_left: 10
      @btn_stop_timer.hide
      @btn_stop_timer.click do
        @timer.stop
        @btn_stop_timer.hide
      end
    end
  end

  stack margin: 10, width: 1.0, height: 200 do
    background black
    @console = para ">>", stroke: gainsboro, margin: 10
  end


  def check_ip?(ip)
    ip =~ Regexp.union([Resolv::IPv4::Regex, Resolv::IPv6::Regex]) ? true : false
  end

  def check_port?(port)
    (1..65535).include? port.to_i
  end

  def check_latitude?(lat)
    regex = /^-?([1-8]?\d(?:\.\d{1,})?|90(?:\.0{1,6})?)$/
    regex =~ lat ? true : false
  end

  def check_longitude?(lon)
    regex = /^-?((?:1[0-7]|[1-9])?\d(?:\.\d{1,})?|180(?:\.0{1,})?)$/
    regex =~ lon ? true : false
  end

  def check_request?(request, timer)
    return false unless (request[:single].checked? or request[:multiple].checked?)
    if request[:multiple].checked?
      return unless timer.to_i > 0
    end
    return true
  end

  def send_request(data)
    # REQUEST participants/find
    # User 3;44.838124,11.619786;find "water"
    begin
      @console.replace(">> Try to connect...\n")
      socket = TCPSocket.new(data[:ip].text, data[:port].text.to_i)
      @console.replace(@console.text + ">> Connected to " + data[:ip].text + \
        ":" + data[:port].text + "\n")
      request_heaader = "REQUEST " + data[:app].text + "\n"
      request_body = "User " + data[:user].text + ";" + data[:lat].text + "," + \
        data[:lon].text + ";" + data[:service].text
      socket.puts(request_heaader)
      socket.puts(request_body)
      if data[:request][:multiple].checked?
        @console.replace(@console.text + ">> Sent request number #{@count}\n")
      else
        @console.replace(@console.text + ">> Sent request\n")
      end
    rescue Exception => e
      @console.replace(">> ERROR\n")
      @console.replace(@console.text + ">> Unable to connect to the controller\n")
      @console.replace(@console.text + ">> #{e.message}\n")
    else
      socket.close
      @console.replace(@console.text + ">> Closed socket\n")
    end
  end

  def randomLocation(lat, lon, r)
    # returns a random location near by the one provided
    # @param  lat [Float] latitude
    # @param  lon [Float] longitude
    # @param  r [Integer] radius in meters
    #
    # @return [Array] array containing latitude and longitude of the new location

    u = rand
    v = rand

    # Convert radius from meters to degrees
    radius = r.to_f / METERS_IN_DEGREE

    w = radius * Math.sqrt(u)
    t = 2 * Math::PI * v

    x = (w * Math.cos(t)) / Math.cos(lat)
    y = w * Math.sin(t)

    [(y + lat).to_s, (x + lon).to_s]
  end

  def randomLocation2(lat, lon, r)
    max_radius = Math.sqrt((max_dist_meters ** 2) / 2.0)

    lat_offset = rand(10 ** (Math.log10(max_radius / 1.11)-5))
    lon_offset = rand(10 ** (Math.log10(max_radius / 1.11)-5))

    lat += [1,-1].sample * lat_offset
    lon += [1,-1].sample * lon_offset
    lat = [[-90, lat].max, 90].min
    lon = [[-180, lon].max, 180].min

    [lat, lon]
  end

end
