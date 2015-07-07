#[macro_use]
extern crate kiss_ui;
use kiss_ui::prelude::*;
use kiss_ui::button::Button;

use std::env;

#[test]
fn change_name() {
	env::set_var("KISSUI_AUTOCLOSE", "2");
	kiss_ui::show_gui(|| {
		let btn = Button::new().set_name("foo");

		let window = Dialog::new(btn);

		let name = btn.get_name().unwrap();
		assert_eq!(name.to_string(), "foo");
		drop(name);
		btn.set_name("bar");
		assert_eq!("bar", btn.get_name().unwrap().to_string());

		window
	} );
	std::thread::sleep_ms(2000);
}
