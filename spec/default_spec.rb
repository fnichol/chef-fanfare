require 'chefspec'

describe 'fanfare::default' do
  let (:chef_run) { ChefSpec::ChefRunner.new.converge 'fanfare::default' }
  it 'should do something' do
    pending 'Your recipe examples go here.'
  end
end
