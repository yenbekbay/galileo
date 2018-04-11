#import "GLLanguageChoiceTableViewCell.h"

#import "UIView+AYUtils.h"
#import <Bohr/BOTableViewCell+Subclass.h>

CGFloat const kLanguageChoiceTableViewPickerItemHeight = 40;

@implementation GLLanguageChoiceTableViewCell

#pragma mark BOTableViewCell

- (void)setup {
    self.pickerView = [UIPickerView new];
    self.pickerView.backgroundColor = [UIColor clearColor];
    self.pickerView.dataSource = self;
    self.pickerView.delegate = self;
    self.expansionView = self.pickerView;
}

- (CGFloat)expansionHeight {
    return kLanguageChoiceTableViewPickerItemHeight * 3;
}

- (void)settingValueDidChange {
    NSUInteger index = [self.languageCodes indexOfObject:self.setting.value];
    if (index != NSNotFound) {
        self.detailTextLabel.text = self.languageDescriptions[index];
        [self.pickerView selectRow:(NSInteger)index inComponent:0 animated:NO];
    }
}

#pragma mark UIPickerViewDelegate

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return (NSInteger)self.languageCodes.count;
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

- (CGFloat)pickerView:(UIPickerView *)pickerView rowHeightForComponent:(NSInteger)component {
    return kLanguageChoiceTableViewPickerItemHeight;
}

- (CGFloat)pickerView:(UIPickerView *)pickerView widthForComponent:(NSInteger)component {
    return self.width;
}

- (UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(UIView *)view {
    UILabel *label = (UILabel *)view;
    if (!label) {
        label = [UILabel new];
        label.font = self.mainFont;
        label.textColor = self.mainColor;
        label.textAlignment = NSTextAlignmentCenter;
    }
    label.text = self.languageDescriptions[(NSUInteger)row];
    return label;
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    self.setting.value = self.languageCodes[(NSUInteger)row];
}

@end
