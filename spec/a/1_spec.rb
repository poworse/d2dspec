RSpec.configure do |rspec|
  rspec.register_ordering(:global) do |items|
    items.reverse
  end
end

RSpec.describe "example as block arg to it, before, and after" do
  before do |example|
    #expect(example.description).to eq("is the example object")
    puts "Start #{example.description}"
  end

  after do |example|
    #expect(example.description).to eq("is the example object")
    puts "End #{example.description}"
  end

  it "is the example object" do |example|
    expect(example.description).to eq("is the example object")
  end

  it "Example 1" do |example|
    expect(example.description).to eq("Example 1")
  end

  it "Example 2" do |example|
    expect(example.description).to eq("Example 12")
  end
end