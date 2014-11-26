# require "/d2dbq/bin/setenv.rb"
require "#{$env["bq_home"]}/bin/common.rb"
require 'net/http'
require 'base64'
require 'cgi'
class Report

  @@passed_count = 0
  @@failed_count = 0
  @@pending_count = 0
  @@total_count = 0
  @@status = "InProgress"

  #def initialize(runner, suite)

  #end

  def initialize(json_formatter, html_formatter)
    @json_formatter = json_formatter.output_hash
    @html_formatter = html_formatter
    @build_number = CommonUtil.get_installed_d2d_version
    #@build_number = "1111.1"
    if @json_formatter[:summary][:failure_count] > 0
      @bq_status = "Failed"
    else
      @bq_status = "Passed"
    end
  end


  def upload_report

    html = ""
    File.open(@html_formatter.output, 'rb') do |file|
      html = html + file.read
    end
    html = Base64.strict_encode64 (html)
    #html = "PCFET0NUWVBFIGh0bWw+CjxodG1sIGxhbmc9J2VuJz4KPGhlYWQ+CiAgPHRpdGxlPlJTcGVjIHJlc3VsdHM8L3RpdGxlPgogIDxtZXRhIGh0dHAtZXF1aXY9IkNvbnRlbnQtVHlwZSIgY29udGVudD0idGV4dC9odG1sOyBjaGFyc2V0PXV0"
    #html = CGI.escapeHTML(html)
    # html = "aa"

    @url = "http://mabji01-hm02:3000/bqinfos/linuxreport"
    @uri = URI.parse @url

    json_req = "{\"bq_name\":\"#{$bq["report"]["subject"]}\", \"build_number\":\"#{@build_number}\", \"html\":\"#{html}\"}"

    request = Net::HTTP::Post.new(@url)
    request.add_field "Content-Type", "application/json"
    request.add_field "Accept", "application/json"
    request.body = json_req
    http = Net::HTTP.new(@uri.host, @uri.port)
    response = http.request(request)
  end

  def self.update_portal(data )
    if data.instance_of?(RSpec::Core::Example)
      if data.exception.nil?
        @@passed_count = @@passed_count + 1

      else
        @@failed_count = @@failed_count + 1
      end
      @@status = "InProgress"
      @@total_count = @@passed_count + @@failed_count
    else
      @@total_count = data[:summary][:example_count]
      @@failed_count = data[:summary][:failure_count]
      @@pending_count = data[:summary][:pending_count]
      @@passed_count = @@total_count - @@failed_count - @@pending_count

      if @@failed_count > 0
        @@status = "Failed"
      else
        @@status = "Passed"
      end
    end


    build_number = CommonUtil.get_installed_d2d_version





    #@case_num_remain = @case_num_total - @case_num_pass - @case_num_failure - @case_num_error
    @url = "http://mabji01-hm02:3000/bqinfos/updatedb"
    @uri = URI.parse @url

    json_req = "{\"bqname\":\"#{$bq["report"]["subject"]}\", \"casenumber\":#{@@total_count}, \"passedcasenumber\":#{@@passed_count}, \"failedcasenumber\":#{@@failed_count}, \"remaincasenumber\":#{@@pending_count}, \"runmachine\":\"#{$env["hostname"]}\", \"buildnumber\":\"#{build_number}\", \"status\":\"#{@@status}\", \"comment\":\"\", \"platform\":\"#{$env["system"]}\", \"owner\":\"mabji01\"}"

    request = Net::HTTP::Post.new(@url)
    request.add_field "Content-Type", "application/json"
    request.add_field "Accept", "application/json"
    request.body = json_req
    http = Net::HTTP.new(@uri.host, @uri.port)
    response = http.request(request)
  end


  def create
    if !CommonUtil.directory_exists?(File.join($home, "report", "html", @build_number.to_s))
      Dir.mkdir(File.join($home, "report", "html", @build_number.to_s.to_s))
    end


    #puts @json_formatter.inspect

    @report_file = File.join($home, "report", "html", @build_number.to_s.to_s, "#{@build_number}.html")
    File.open(@report_file, "w") do |file|
      file.write "From: root@mabji01-sl11sp2x64-1.com\n"
      file.write "To: #{$bq["report"]["mail_list"]}\n"
      file.write "MIME-Version: 1.0\n"
      file.write "Content-Type: multipart/alternative;\n"
      file.write "Subject: #{$bq["report"]["subject"]} ##{@build_number}# #{@bq_status.upcase}\n"
      file.write "Content-Type: text/html\n"
      file.write "<html>"
      file.write "<body>"
      file.write "<STYLE>.boldtable, .boldtable TD, .boldtable TH{font-size:10pt;border: 1px solid #CCCCCC;}</STYLE>"
      file.write "<FONT size='4'>"
      file.write "<p>Summary:  #{@json_formatter[:summary_line]}<p><br/>"
      file.write "<p>For details please go http://mabji01-hm02:3000/bqinfos/report?bq_name=#{$bq["report"]["subject"].gsub(" ", "_").downcase}&build_number=#{@build_number.gsub(".", "_")}<p>"
      file.write "<table>"
      file.write "<tr><th>Example Descryption</th>"
      file.write "<th>Status</th>"
      file.write "<th>Run Time</th></tr>"
      @json_formatter[:examples].each do |example|
        file.write "<tr>"
        file.write "<td>#{example[:full_description]}</td>"
        file.write "<td>#{example[:status]}</td>"
        file.write "<td>#{format("%.2f",example[:run_time])}</td>"
        file.write "</tr>"
      end
      file.write "</table></BR>"
      file.write "</body>"
      file.write "</html>"
    end
  end

  def send
    `cat #{@report_file} | sendmail -t`
  end
  
end
