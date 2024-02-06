.PHONY: images

arhashem/xr-wrl7:
	docker build docker -f docker/WRL7.Dockerfile -t arhashem/xr-wrl7

arhashem/xr-centos:
	docker build --platform=linux/x86_64 docker -f docker/Centos.Dockerfile -t arhashem/xr-centos

images: wrl7 centos

