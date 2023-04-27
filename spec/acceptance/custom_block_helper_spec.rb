require 'flavour_saver'

describe 'Fixture: custom_block_helper.hbs' do
  subject { FS.evaluate_file(template, context).gsub(/[\s\r\n]+/, ' ').strip }
  let(:template) { File.expand_path('../../fixtures/custom_block_helper.hbs', __FILE__) }
  let(:context)  { double(:context) }

  before(:each) do
    FlavourSaver::Helpers.reset_helpers
  end

  describe 'method helper' do
    it 'renders correctly' do
      def three_times
        (1..3).map do |i|
          yield.contents i
        end.join ''
      end
      FlavourSaver.register_helper(method(:three_times))
      subject.should == "1 time. 2 time. 3 time."
    end
  end

  describe 'proc helper' do
    it 'renders correctly' do
      FlavourSaver.register_helper(:three_times) { |&b|
        (1..3).map do |i|
          b.call.contents i
        end.join ''
      }
      subject.should == "1 time. 2 time. 3 time."
    end
  end
end
