require 'spec_helper' 

describe Exist::GetReadingInterface, :existdb => true do 
  include FileHelpers

  def valid_request_test(type)
    blob = File.read(fixture_file 'tei.xml')
    response = Exist::GetReadingInterface.execute(blob, type)
    expect(response.code).to eq 200 
    expect { 
      Nokogiri::XML(response) { |c| c.strict }
    }.not_to raise_error 
  end

  it 'raises a 400 when passed an invalid reading interface type' do 
    path = fixture_file 'tei.xml'
    e = Exceptions::ExistError
    expect { Exist::GetReadingInterface.execute(path, 'x') }.to raise_error e
  end

  it 'returns valid xhtml when teibp is requested' do 
    valid_request_test 'teibp'
  end

  it 'returns valid xhtml when tapas-generic is requested' do 
    valid_request_test 'tapas-generic'
  end
end
    
