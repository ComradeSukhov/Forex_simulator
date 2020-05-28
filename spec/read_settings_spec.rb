require 'rmagick'
require 'json'
require 'rspec'
require_relative '../classes'


describe 'read_settings' do
  before(:each) do
    graph = GraphWindow.new
    @x = graph.send:read_settings
  end


  it 'should return a hash' do

    expect(@x).to be_a(Hash)

  end

  it 'should contein 22 pairs' do

    expect(@x.size).to eq(22)

  end

  it 'should not contein nill values' do
    @x.each_value{ |v| expect(v).not_to be_nil }

  end

  it 'should contein 5 string values' do
    @x
  end

end

