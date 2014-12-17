require 'spec_helper'

describe CoreFileUpserter do 
  include FileHelpers

  def params 
    { :depositor => "test",
      :nid => "test", 
      :access => "public", 
      :collection => "023",
      :file => fixture_file("tei_copy.xml"),
    }
  end

  def assign_collection
    @collection = Collection.new
    @collection.nid = params[:collection]
    @collection.depositor = params[:depositor]
    @collection.save!
  end

  subject(:core_file) do 
    CoreFile.find_by_nid(params[:nid])
  end

  RSpec.shared_examples "a metadata assigning operation" do 
    its(:depositor) { should eq params[:depositor] } 
    its(:og_reference) { should eq params[:collection] } 
    its(:drupal_access) { should eq params[:access] } 
  end

  RSpec.shared_examples "a tei file updating operation" do 
    before(:all) do 
      core = CoreFile.find_by_nid(params[:nid])
      @tei = core.canonical_object(:return_as => :models) 
    end

    subject(:tei) { @tei } 
    its(:class) { should eq TEIFile } 
    its(:canonical?) { should be true }

    it "cleans up the file" do 
      expect(File.exists?(params[:file])).to be false 
    end

    # have to be using file generated from fixture_file("tei.xml").
    it "assigns content to the core_file" do
      file_data = File.read(fixture_file "tei.xml")  
      expect(tei.content.content).to eq file_data 
    end

    it "never creates more than one tei file" do 
      core_file = tei.core_file
      expect(core_file.content_objects.count).to eq 1 
    end
  end

  context "when creating a new core file" do 
    context "with a valid collection" do 
      before(:all) do 
        copy_fixture("tei.xml", "tei_copy.xml")
        assign_collection
        CoreFileUpserter.upsert(params) 
      end

      after(:all) { ActiveFedora::Base.delete_all }
      
      it "creates the core file" do 
        expect(core_file.class).to eq CoreFile 
      end

      it "assigns the core file to the requested collection" do 
        expect(core_file.collection.pid).to eq @collection.pid 
      end

      it_should_behave_like "a metadata assigning operation" 
      it_should_behave_like "a tei file updating operation"
    end

    context "without a valid collection" do 
      before(:all) do 
        copy_fixture("tei.xml", "tei_copy.xml")
        CoreFileUpserter.upsert(params)
      end

      after(:all) { ActiveFedora::Base.delete_all } 

      it "creates the core file" do 
        expect(core_file.class).to eq CoreFile 
      end

      it "assigns the core file to the phantom collection" do 
        expect(core_file.collection).to eq Collection.phantom_collection
      end

      it_should_behave_like "a metadata assigning operation"
      it_should_behave_like "a tei file updating operation"
    end
  end

  context "when updating an existing core file" do 
    before(:all) do 
      assign_collection
      copy_fixture("tei.xml", "tei_copy.xml")
      # Build the core file we intend to update
      core = FactoryGirl.create(:core_file) 
      core.nid = params[:nid]
      core.og_reference = params[:collection]
      core.save! ; core.collection = @collection ; core.save!

      # Build the tei_file attached to it 
      @tei = TEIFile.new 
      @tei.depositor = params[:depositor]
      filedata = File.read(fixture_file "tei_full_metadata.xml")
      @tei.add_file(filedata, "content", "tei_full_metadata.xml")  
      @tei.canonize
      @tei.save! ; @tei.core_file = core ; @tei.save! 

      CoreFileUpserter.upsert(params)
    end

    after(:all) { ActiveFedora::Base.delete_all } 

    it "updates the preexisting core file" do 
      expect(CoreFile.count).to eq 1 
    end

    it "revisions rather than overwrites file data" do 
      expect(@tei.content.versions.length).to eq 2 
    end

    it_should_behave_like "a metadata assigning operation"
    it_should_behave_like "a tei file updating operation" 
  end
end
