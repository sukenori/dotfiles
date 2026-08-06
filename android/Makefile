# 設定ファイルを読み込む
-include $(HOME)/.config/atcoder.conf

attach:
	ssh -t $(ATCODER_HOST) "wsl -- docker exec -it $(CONTAINER) bash"

copy:
	ssh -o RequestTTY=no $(ATCODER_HOST) "wsl --exec docker exec $(CONTAINER) cat $(WORKSPACE)/bundled.txt" | termux-clipboard-set
	@echo "copied: $(shell date +%H:%M:%S)"

watch:
	@echo "監視中... Ctrl-C で停止"
	watch -n 2 make copy