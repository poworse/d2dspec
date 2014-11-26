# require "/d2dbq/bin/setenv.rb"
require 'pty'
require 'expect'
require 'net/ssh'


class CommonUtil
  
  def self.file_exist?(file_path)
    FileTest::exist? file_path
  end

  def self.directory_exists?(directory)
    File.directory?(directory)
  end

  def self.build_install?
    file_exist? "#{$env["d2d_home"]}/RELVERSION"
  end
  
  def self.get_installed_d2d_version
    if build_install?
      version = /\d\d\d\d\.\d/.match(File.read("#{$env["d2d_home"]}/RELVERSION"))
      version[0]
    else
      "0000.0"
    end 
    
    
  end
  
  def self.get_latest_d2d_version
    File.read("#{$env["build_home"]}/d2dversion").chomp 
  end
  
  def self.install_latest_build
    latest_version = get_latest_d2d_version
    $logger.info latest_version
    latest_build = ""
    $logger.info $env["build_home"]
    Dir.foreach($env["build_home"]) do |file|
      $logger.info file
      if file.include? latest_version
        latest_build = "#{$env["build_home"]}/#{file}"
        break
      end
    end
    
    if latest_build.empty?
      1
    else
      $logger.info latest_build
      install_build(latest_build)
    end
  end
  
  
  
  def self.install_build(build_path)
    PTY.spawn(build_path) do |r_f,w_f,pid|
    #w_f.sync = true

     $expect_verbose = true
    
     r_f.expect(/.*More.*/) do
       w_f.print "q"
     end
    
     #r_f.expect(/.*Do you want to continue the installation process\? \[y|n\] \(default: n\) .*/) do
     r_f.expect(/.*Do you want.*/) do
       w_f.print "y\n"
     end
    
     r_f.expect(/.*Starting server .*\[Completed\]/) do
       w_f.print "\n"
     end
    end
  end
  
  def self.uninstall_build
    PTY.spawn("#{$env["d2d_home"]}/bin/d2duninstall") do |r_f,w_f,pid|
    #w_f.sync = true
      begin
        $expect_verbose = true

        r_f.expect(/.*Do you want to uninstall Arcserve UDP Agent.*/) do
          w_f.print "y\n"
        end

        #r_f.expect(/.*Do you want to continue the installation process\? \[y|n\] \(default: n\) .*/) do
        r_f.expect(/.* you want to uninstall the license module.*/) do
          w_f.print "y\n"
        end

        r_f.expect(/The Arcserve UDP Agent(Linux) was successfully removed.*/) do
          w_f.print "\n"
        end
      rescue Errno::EIO
      ensure
        Process.wait pid
      end
      puts $?.exitstatus
    end
  end

  def self.all_volume_mount?(hostname, user, pwd, expect) 
    act = ""  
    Net::SSH.start( hostname, user, :password => pwd ) do |ssh|
      act = ssh.exec!('mount | grep -cE "mbr|gpt"').chomp
    end

    $logger.info "++++++ expect is #{expect};  #{hostname} has mounted #{act} volumes. +++++"

#    return act.to_i == expect ? true : false
    return_value = false
    if act.to_i == expect
       return_value = true
    else
       expect = expect - 2
       if act.to_i == expect
          return_value = true
       end
    end

    return return_value

  end

  def self.exec_remote(hostname, user, pwd, cmd)
    act = nil
    Net::SSH.start( hostname, user, :password => pwd ) do |ssh|
      act = ssh.exec!(cmd)
    end
    
    return act
  end
  
  def self.remote_machine_reboot?(remote)
    `ping #{remote} -c 1`
    if $?.exitstatus == 0
      true
    else
      false
    end
  end
  
end

