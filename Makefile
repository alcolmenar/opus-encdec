INPUT_DIR=./src
OUTPUT_DIR=./dist
OUTPUT_DIR_UNMINIFIED=./dist
EMCC_OPTS=-O3 -s NO_DYNAMIC_EXECUTION=1 -s NO_FILESYSTEM=1
DEFAULT_EXPORTS:='_malloc','_free'

LIBOPUS_ENCODER_SRC=$(INPUT_DIR)/oggOpusEncoder.js
LIBOPUS_DECODER_SRC=$(INPUT_DIR)/oggOpusDecoder.js

LIBOPUS_ENCODER_MIN=$(OUTPUT_DIR)/libopus-encoder.min.js
LIBOPUS_ENCODER=$(OUTPUT_DIR_UNMINIFIED)/libopus-encoder.js
LIBOPUS_DECODER_MIN=$(OUTPUT_DIR)/libopus-decoder.min.js
LIBOPUS_DECODER=$(OUTPUT_DIR_UNMINIFIED)/libopus-decoder.js
LIBSPEEXDSP_RESAMPLER_MIN=$(OUTPUT_DIR)/resampler.min.js
LIBSPEEXDSP_RESAMPLER=$(OUTPUT_DIR_UNMINIFIED)/resampler.js

LIBOPUS_DIR=./opus
LIBOPUS_OBJ=$(LIBOPUS_DIR)/.libs/libopus.a
LIBOPUS_ENCODER_EXPORTS:='_opus_encoder_create','_opus_encode_float','_opus_encoder_ctl','_opus_encoder_destroy'
LIBOPUS_DECODER_EXPORTS:='_opus_decoder_create','_opus_decode_float','_opus_decoder_ctl','_opus_decoder_destroy'

ENCODER_WORKLET_SRC=$(INPUT_DIR)/encoderWorker.js
ENCODER_WORKLET=$(OUTPUT_DIR)/encoderWorker.js
ENCODER_WORKLET_MIN=$(OUTPUT_DIR)/encoderWorker.min.js
DECODER_WORKLET_SRC=$(INPUT_DIR)/decoderWorker.js
DECODER_WORKLET=$(OUTPUT_DIR)/decoderWorker.js
DECODER_WORKLET_MIN=$(OUTPUT_DIR)/decoderWorker.min.js
FREEQUEUE_SRC=$(INPUT_DIR)/free-queue.js

LIBSPEEXDSP_DIR=./speexdsp
LIBSPEEXDSP_OBJ=$(LIBSPEEXDSP_DIR)/libspeexdsp/.libs/libspeexdsp.a
LIBSPEEXDSP_EXPORTS:='_speex_resampler_init','_speex_resampler_process_interleaved_float','_speex_resampler_destroy'

default: $(ENCODER_WORKLET) $(DECODER_WORKLET) $(ENCODER_WORKLET_MIN) $(DECODER_WORKLET_MIN)

cleanDist:
	rm -rf $(OUTPUT_DIR)
	mkdir $(OUTPUT_DIR)

cleanAll: cleanDist
	rm -rf $(LIBOPUS_DIR) $(LIBSPEEXDSP_DIR)

test:
	# Tests need to run relative to `dist` folder for wasm file import
	cd $(OUTPUT_DIR); node --expose-wasm ../test.js

.PHONY: test

$(LIBOPUS_DIR)/autogen.sh $(LIBSPEEXDSP_DIR)/autogen.sh:
	git submodule update --init

$(LIBOPUS_OBJ): $(LIBOPUS_DIR)/autogen.sh
	cd $(LIBOPUS_DIR); ./autogen.sh
	cd $(LIBOPUS_DIR); emconfigure ./configure --disable-extra-programs --disable-doc --disable-intrinsics --disable-rtcd --disable-stack-protector
	cd $(LIBOPUS_DIR); emmake make

$(LIBSPEEXDSP_OBJ): $(LIBSPEEXDSP_DIR)/autogen.sh
	cd $(LIBSPEEXDSP_DIR); ./autogen.sh
	cd $(LIBSPEEXDSP_DIR); emconfigure ./configure --disable-examples --disable-neon
	cd $(LIBSPEEXDSP_DIR); emmake make

$(ENCODER_WORKLET): $(LIBOPUS_ENCODER_SRC) $(ENCODER_WORKLET_SRC) $(LIBOPUS_OBJ) $(LIBSPEEXDSP_OBJ)
	emcc -o $@ $(EMCC_OPTS) -s BINARYEN_ASYNC_COMPILATION=0 -s SINGLE_FILE=1 -g3 -s EXPORTED_FUNCTIONS="[$(DEFAULT_EXPORTS),$(LIBOPUS_ENCODER_EXPORTS),$(LIBSPEEXDSP_EXPORTS)]" --post-js $(LIBOPUS_ENCODER_SRC) --post-js $(ENCODER_WORKLET_SRC) $(LIBOPUS_OBJ) $(LIBSPEEXDSP_OBJ)

$(DECODER_WORKLET): $(LIBOPUS_DECODER_SRC) $(FREEQUEUE_SRC) $(DECODER_WORKLET_SRC) $(LIBOPUS_OBJ) $(LIBSPEEXDSP_OBJ)
	emcc -o $@ $(EMCC_OPTS) -s BINARYEN_ASYNC_COMPILATION=0 -s SINGLE_FILE=1 -g3 -s EXPORTED_FUNCTIONS="[$(DEFAULT_EXPORTS),$(LIBOPUS_DECODER_EXPORTS),$(LIBSPEEXDSP_EXPORTS)]" --post-js $(LIBOPUS_DECODER_SRC) --post-js $(FREEQUEUE_SRC) --post-js $(DECODER_WORKLET_SRC) $(LIBOPUS_OBJ) $(LIBSPEEXDSP_OBJ)

$(ENCODER_WORKLET_MIN): $(LIBOPUS_ENCODER_SRC) $(ENCODER_WORKLET_SRC) $(LIBOPUS_OBJ) $(LIBSPEEXDSP_OBJ)
	emcc -o $@ $(EMCC_OPTS) -s BINARYEN_ASYNC_COMPILATION=0 -s SINGLE_FILE=1 -s EXPORTED_FUNCTIONS="[$(DEFAULT_EXPORTS),$(LIBOPUS_ENCODER_EXPORTS),$(LIBSPEEXDSP_EXPORTS)]" --post-js $(LIBOPUS_ENCODER_SRC) --post-js $(ENCODER_WORKLET_SRC) $(LIBOPUS_OBJ) $(LIBSPEEXDSP_OBJ)

$(DECODER_WORKLET_MIN): $(LIBOPUS_DECODER_SRC) $(FREEQUEUE_SRC) $(DECODER_WORKLET_SRC) $(LIBOPUS_OBJ) $(LIBSPEEXDSP_OBJ)
	emcc -o $@ $(EMCC_OPTS) -s BINARYEN_ASYNC_COMPILATION=0 -s SINGLE_FILE=1 -s EXPORTED_FUNCTIONS="[$(DEFAULT_EXPORTS),$(LIBOPUS_DECODER_EXPORTS),$(LIBSPEEXDSP_EXPORTS)]" --post-js $(LIBOPUS_DECODER_SRC) --extern-pre-js $(FREEQUEUE_SRC) --post-js $(DECODER_WORKLET_SRC) $(LIBOPUS_OBJ) $(LIBSPEEXDSP_OBJ)

