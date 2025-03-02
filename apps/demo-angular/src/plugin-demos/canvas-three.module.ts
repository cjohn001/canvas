import { NgModule, NO_ERRORS_SCHEMA } from '@angular/core';
import { NativeScriptCommonModule, NativeScriptRouterModule } from '@nativescript/angular';
import { CanvasThreeComponent } from './canvas-three.component';

@NgModule({
	imports: [NativeScriptCommonModule, NativeScriptRouterModule.forChild([{ path: '', component: CanvasThreeComponent }])],
	declarations: [CanvasThreeComponent],
	schemas: [NO_ERRORS_SCHEMA],
})
export class CanvasThreeModule {}
