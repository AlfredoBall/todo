import { ComponentFixture, TestBed } from '@angular/core/testing';

import { DynamicHtmlLoader } from './dynamic-html-loader';

describe('DynamicHtmlLoader', () => {
  let component: DynamicHtmlLoader;
  let fixture: ComponentFixture<DynamicHtmlLoader>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [DynamicHtmlLoader]
    })
    .compileComponents();

    fixture = TestBed.createComponent(DynamicHtmlLoader);
    component = fixture.componentInstance;
    await fixture.whenStable();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
