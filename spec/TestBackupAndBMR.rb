#$home = Pathname.new(File.dirname(__FILE__)).realpath
require "#{$home}/bin/d2doper.rb"

RSpec.describe "As a user, I want to do a full backup and then submit a BMR from NFS destination: " do
  it "List nodes, and delete all nodes if there is node existed" do |example|
    nodes = D2D.list_node
    expect(nodes).not_to be_nil

    if nodes.size != 0
  		$logger.info("Delete all nodes...")
      expect(D2D.delete_node("all")).to eq(0)
    else
  		$logger.info("There is no nodes need be deleted.")
  	end
  end

  it "Add some nodes" do
    $logger.info("Start to add nodes.")
  	$bq["nodes"].each do |key, node|
  		res = D2D.add_node(node["node_name"], :user=>node["node_user"], :password=>node["node_pwd"])
      expect(res).to eq(0)
  	end
  end

  it "Submit a full backup job to a NFS destination with compression" do
    $logger.info("Submit full backup jobs to nfs destination.")
    expect(D2D.submit_backup("nfs", "jobtype" => 3)).to eq(0)
  end

  it "Submit a BMR job via restorevm cmd from NFS destination" do
    $logger.info("Submit BMR jobs from nfs via d2drestorevm.")
    jobs= ""
    $bq["nodes"].each do |key, node|
      expect(D2D.bmr_restorevm("restorevm_script", "job_name" => "#{node["node_name"]}-bmr", "vm_name" => "verify_#{node["node_name"]}", "storage_location" => $bq["backup_destination"]["nfs"]["path"], "source_node" => node["node_name"], "guest_hostname" => "#{node["node_name"]}-test")).to eq(0)
      jobs = "#{jobs}#{node["node_name"]}-bmr;"
    end
    expect(D2D.wait_jobs(jobs.chop)).to eq(0)
    $bq["nodes"].each do |key, node|
      while true
        $logger.info "Start to check #{node["node_name"]}-test..."
        if CommonUtil.remote_machine_reboot?(node["node_name"] + "-test")
          expect(CommonUtil.all_volume_mount?(node["node_name"] + "-test", node["node_user"], node["node_pwd"], 12)).to be true
          break
        else
          sleep(60)
        end
      end
    end
  end
end

RSpec.describe "As a user, I want to submit an verify backup and then submit a BMR from CIFS destination: " do
  it "Delete all nodes" do
    $logger.info("Submit full backup jobs to nfs destination.")
    expect(D2D.delete_node("all")).to eq(0)
  end

  it "Add some nodes back again" do
    $logger.info("Start to add nodes.")
    $bq["nodes"].each do |key, node|
      res = D2D.add_node(node["node_name"], :user=>node["node_user"], :password=>node["node_pwd"])
      expect(res).to eq(0)
    end
  end

  it "Submit a verify backup job to a CIFS destination" do
    $logger.info("Submit verify backup jobs to cifs destination.")
    expect(D2D.submit_backup("cifs", "jobtype" => 2)).to eq(0)
  end

  it "Submit an incremental backup job to CIFS destination" do
    $logger.info("Submit incremental backup jobs to cifs destination.")
    expect(D2D.submit_backup("cifs", "jobtype" => 4)).to eq(0)
  end

  it "Submit the BMR job from CIFS destination and then check target machines" do
    $logger.info("Submit BMR jobs from cifs via d2drestorevm.")
    #p $bq["encryption"]["pwd"]
    jobs= ""
    $bq["nodes"].each do |key, node|
      expect(D2D.bmr_restorevm("restorevm_script", "job_name" => "#{node["node_name"]}-bmr", "vm_name" => "verify_#{node["node_name"]}", "storage_location" => $bq["backup_destination"]["cifs"]["path"], "storage_username" => $bq["backup_destination"]["cifs"]["user"], "storage_password" => $bq["backup_destination"]["cifs"]["pwd"], "encryption_password" => $bq["encryption"]["pwd"], "source_node" => node["node_name"], "guest_hostname" => "#{node["node_name"]}-test")).to eq(0)
      jobs = "#{jobs}#{node["node_name"]}-bmr;"
    end
    expect(D2D.wait_jobs(jobs.chop)).to eq(0)

    $bq["nodes"].each do |key, node|
      while true
        $logger.info "Start to check #{node["node_name"]}-test..."
        if CommonUtil.remote_machine_reboot?(node["node_name"] + "-test")
          expect(CommonUtil.all_volume_mount?(node["node_name"] + "-test", node["node_user"], node["node_pwd"], 12)).to be true
          break
        else
          sleep(60)
        end
      end
    end
  end

end
