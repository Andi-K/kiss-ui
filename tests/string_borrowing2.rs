#[macro_use]
extern crate kiss_ui;
use kiss_ui::prelude::*;
use kiss_ui::button::Button;

use std::env;

#[test]
#[should_panic]
fn string_borrowing2() {
	env::set_var("KISSUI_AUTOCLOSE", "2");
	kiss_ui::show_gui(|| {
		let btn = Button::new().set_name("foo");

		let window = Dialog::new(btn);

		let name = btn.get_name().unwrap().to_string();
		btn.set_name("bar"); // should panic here

		window
	} );
	std::thread::sleep_ms(2000);
}
