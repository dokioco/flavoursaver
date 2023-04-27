require 'flavour_saver'

describe 'Fixture: comment.hbs' do
  subject { FS.evaluate_file(template, context).gsub(/[\s\r\n]+/, ' ').strip }
  let(:template) { File.expand_path('../../fixtures/comment.hbs', __FILE__) }
  let(:context)  { double(:context) }

  it 'renders correctly' do
    subject.should == "I am a very nice person!"
  end
end
