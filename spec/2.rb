

RSpec.describe "1. example as block arg to it, before, and after" do
  before do |example|
    #expect(example.description).to eq("is the example object")
    puts "Start #{example.description}"
  end

  after do |example|
    #expect(example.description).to eq("is the example object")
    puts "End #{example.description}"
  end

  it "1. is the example object" do |example|
    expect(example.description).to eq("is the example object")
  end

  it "2. Example 1" do |example|
    expect(example.description).to eq("Example 1")
  end

  it "3. Example 2" do |example|
    expect(example.description).to eq("Example 1")
  end
end