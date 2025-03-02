import {CanvasGradientBase} from './common';

export class CanvasGradient extends CanvasGradientBase {
	readonly nativeInstance: any;

	protected constructor(nativeInstance: any) {
		super();
		this.nativeInstance = nativeInstance;
	}

	get native() {
		return this.nativeInstance;
	}

	static fromNative(nativeInstance) {
		return new CanvasGradient(nativeInstance);
	}

	public addColorStop(offset: number, color: string): void {
		if (offset >= 0.0 && offset <= 1.0) {
			this.nativeInstance.addColorStop(
				offset,
				color
			);
		}
	}
}
