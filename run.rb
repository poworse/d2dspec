require 'pathname'
$home = Pathname.new(File.dirname(__FILE__)).realpath
require "#{$home}/bin/setenv.rb"

$json_formatter = ""
$html_formatter = ""

def run
  RSpec::Core::Runner.run(['spec/TestBackupAndBMR.rb'])
  $json_formatter = RSpec.configuration.formatters[1]
  $html_formatter = RSpec.configuration.formatters[2]
end

def update_portal
  Report.update_portal($json_formatter.output_hash)
end

def send_report
  report = Report.new($json_formatter, $html_formatter)
  report.upload_report
  report.create
  report.send
end


if ARGV[0] == "-b"
  while true
    if CommonUtil.get_installed_d2d_version == "0000.0"
      CommonUtil.install_latest_build
      sleep(15)
      run
      update_portal
      send_report
    elsif CommonUtil.get_installed_d2d_version != CommonUtil.get_latest_d2d_version
      CommonUtil.uninstall_build
      CommonUtil.install_latest_build
      sleep(15)
      run
      update_portal
      send_report
    else
      puts "The build is the latest build, BQ will wait 5 mins to check again."
    end

    sleep(300)
  end
elsif ARGV[0].nil?
  run
  update_portal
  send_report
end






# here's your json hash
# p formatter.output_hash
