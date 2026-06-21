.PHONY: install

LEMURS_DIR = /etc/lemurs
SV_DIR = /etc/sv

install:
	install -Dm644 config.toml                     $(LEMURS_DIR)/config.toml
	install -Dm755 wms/dwm                         $(LEMURS_DIR)/wms/dwm
	install -Dm755 xsetup.sh                       $(LEMURS_DIR)/xsetup.sh

install-runit:
	install -Dm755 runitservice/lemurs/run         $(SV_DIR)/lemurs/run
	install -Dm755 runitservice/lemurs/finish      $(SV_DIR)/lemurs/finish
