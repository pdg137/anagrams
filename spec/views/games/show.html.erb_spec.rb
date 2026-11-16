require 'rails_helper'

RSpec.describe "games/show", type: :view do
  before do
    assign(:game, Game.create!(log: 'ABCD'))
  end

  it "renders the edit link" do
    render
    expect(rendered).to include("Edit this game")
  end
end
