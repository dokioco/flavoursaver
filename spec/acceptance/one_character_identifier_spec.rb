require 'flavour_saver'

describe 'Fixture: one_character_identifier.hbs' do
  subject { FlavourSaver.evaluate_file(template, context).gsub(/[\s\r\n]+/, ' ').strip }
  let(:template) { File.expand_path('../../fixtures/one_character_identifier.hbs', __FILE__) }
  let(:context)  { double(:context) }

  it 'renders correctly' do
    expect(context).to receive(:a).and_return('foo')
    expect(subject).to eq "foo"
  end
end
