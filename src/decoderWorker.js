class DecoderWorklet extends AudioWorkletProcessor {
  constructor() {
    super();
    this.continueProcess = true;
    this.queue = new FreeQueue(4096);
    this.enqueue = (data) => {
	this.queue.push([data], data.length);	
    };
    this.port.onmessage = ({ data }) => {
      if (this.decoder) {
        switch (data.command) {
	  case 'decode':
	    this.decoder.decodeRaw(data.pages, this.enqueue);
	    break;

          default:
              // Ignore any unknown commands and continue recieving commands
        }
      }

      switch (data.command) {
        case 'close':
          this.continueProcess = false;
          break;

        case 'init':
          this.decoder = new OggOpusDecoder(data, Module);
          this.port.postMessage({ message: 'ready' });
          break;

        default:
            // Ignore any unknown commands and continue receiving commands
      }
    };
  }

  process(_inputs, outputs) {
    if (this.queue.isFrameAvailable(1)) {
      this.queue.pull(outputs[0], 128);
    }

    return this.continueProcess;
  }
}

registerProcessor('decoder-worklet', DecoderWorklet);
