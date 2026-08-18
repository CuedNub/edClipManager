.PHONY: build install uninstall push clean

build:
	cargo build --release

install:
	bash scripts/install.sh

uninstall:
	bash scripts/uninstall.sh

clean:
	cargo clean

push:
	@read -p "Masukkan pesan commit: " msg; \
	git add .; \
	git commit -m "$$msg"; \
	git push origin main
