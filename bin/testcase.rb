class TestCase < Test::Unit::TestCase
  def teardown
   if !$report.nil?
     if passed?
       $report.add_pass      
     else
       $report.add_failure
     end
     $report.update_portal
   end
  end
  
end