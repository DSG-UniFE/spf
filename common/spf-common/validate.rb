require 'resolv'

class Validate

  def self.ip?(ip)
    ip =~ (Regexp.union([Resolv::IPv4::Regex, Resolv::IPv6::Regex]) ? true :
    false)
  end

  def self.port?(port)
    port.is_a? Numeric && (1..65535).include? port ? true : false
  end

  def self.latitude?(lat)
    regex = /^-?([1-8]?\d(?:\.\d{1,})?|90(?:\.0{1,6})?)$/
    regex =~ lat ? true : false
  end

  def self.longitude?(lon)
    regex = /^-?((?:1[0-7]|[1-9])?\d(?:\.\d{1,})?|180(?:\.0{1,})?)$/
    regex =~ lon ? true : false
  end

  def self.pig?(pig)
    (Validate.ip? pig[:ip] and Validate.port? pig[:port] and \
      Validate.latitude? pig[:lat] and Validate.latitude? pig[:lat]) ? true :
    false
  end

end
