class EncoderWorklet extends AudioWorkletProcessor {
  constructor() {
    super();
    this.continueProcess = true;
    this.port.onmessage = ({ data }) => {
      if (this.encoder) {
        switch (data.command) {
          case 'getHeaderPages':
            this.postPage(this.encoder.generateIdPage());
            this.postPage(this.encoder.generateCommentPage());
            break;

          case 'done':
            this.encoder.encodeFinalFrame().forEach((pageData) => this.postPage(pageData));
            this.encoder.destroy();
            delete this.encoder;
            this.port.postMessage({ message: 'done' });
            break;

          case 'flush':
            this.postPage(this.encoder.flush());
            this.port.postMessage({ message: 'flushed' });
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
          this.encoder = new OggOpusEncoder(data, Module);
          this.port.postMessage({ message: 'ready' });
          break;

        default:
            // Ignore any unknown commands and continue recieving commands
      }
    };
  }

  process(inputs) {
    if (this.encoder && inputs[0] && inputs[0].length && inputs[0][0] && inputs[0][0].length) {
      this.encoder.encode(inputs[0]).forEach((pageData) => this.postPage(pageData));
    }
    
    return this.continueProcess;
  }

  postPage(pageData) {
    if (pageData) {
      this.port.postMessage(pageData, [pageData.page.buffer]);
    }
  }
}

registerProcessor('encoder-worklet', EncoderWorklet);
