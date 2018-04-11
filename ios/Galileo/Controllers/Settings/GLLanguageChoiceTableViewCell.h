#import <Bohr/BOTableViewCell.h>

@interface GLLanguageChoiceTableViewCell : BOTableViewCell <UIPickerViewDataSource, UIPickerViewDelegate>

@property (nonatomic) UIPickerView *pickerView;
@property (nonatomic) NSArray *languageDescriptions;
@property (nonatomic) NSArray *languageCodes;

@end
