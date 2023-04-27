require 'flavour_saver'

describe 'Fixture: if_else.hbs' do
  subject { FS.evaluate_file(template, context).gsub(/[\s\r\n]+/, ' ').strip }
  let(:context) { Struct.new(:name).new }
  let(:template) { File.expand_path('../../fixtures/if_else.hbs', __FILE__) }

  it 'renders correctly when given a name' do
    context.name = 'Alan'
    subject.should == "Say hello to Alan."
  end

  it 'renders correctly when not given a name' do
    subject.should == "Nobody to say hi to."
  end
end
