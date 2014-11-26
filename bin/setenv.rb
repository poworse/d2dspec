require 'logger'
require 'yaml'

$framework = YAML.load_file "#{$home}/config/framework.config"
$env = $framework["env"]
$log = $framework["log"]
$update = $framework["update"]


$bq = YAML.load_file "#{$home}/config/bq.config"


class MultiIO
  def initialize(*targets)
     @targets = targets
  end

  def write(*args)
    @targets.each {|t| t.write(*args)}
  end

  def close
    @targets.each(&:close)
  end
end

if $logger.nil?
  log_file = File.open("#{$home}/logs/bq.log", "a")
	# $logger = Logger.new("#{$env["bq_home"]}/logs/bq.log", 'daily')
	#$logger = Logger.new MultiIO.new(STDOUT, log_file)
	$logger = Logger.new MultiIO.new(log_file)
	$logger.info("\n\n\n\************************************* New Round Test ********************************************************")
	$logger.info("Initial the logger...")
	case $log["log_level"].upcase
	when "INFO"
		$logger.info("The log level is INFO.")
		$logger.level = Logger::INFO
	when "DEBUG"
		$logger.info("The log level is DEBUG.")
                $logger.level = Logger::DEBUG
	else
		$logger.info("The log level is INFO.")
                $logger.level = Logger::INFO
	end
end

$env["bq_home"] = $home
$env["system"] = `lsb_release -a | grep Description`.split("\t")[1].strip
#$env["system"] = "linux"
$env["hostname"] = `hostname`.chomp


# require "#{$env["bq_home"]}/bin/d2doper.rb"
# require "#{$env["bq_home"]}/bin/testcase.rb"
# require "#{$env["bq_home"]}/bin/common.rb"
require "#{$env["bq_home"]}/bin/report.rb"
require 'rspec'
# require "#{$env["bq_home"]}/test/TestBackupAndBMR.rb"

