//
//  MKStoreObserverClass.m
//  Earth Fortune
//
//  Created by Thomas Suarez on 9/2/10.
//  Copyright 2010 CarrotCorp. All rights reserved.
//

#import "MKStoreObserverClass.h"


@implementation MKStoreObserverClass

/*- (void)paymentQueue:updatedTransactions(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions
{
	for (SKPaymentTransaction *transaction in transactions)
	{
		switch (transaction.transactionState)
		{
			case SKPaymentTransactionStatePurchased:
				// take action to purchase the feature
				[self provideContent: transaction.payment.productIdentifier];
				break;
			case SKPaymentTransactionStateFailed:
				if (transaction.error.code != SKErrorPaymentCancelled)
				{
					// Optionally, display an error here.
				}
				// take action to display some error message
				break;
			case SKPaymentTransactionStateRestored:
				// take action to restore the app as if it was purchased
				[self provideContent: transaction.originalTransaction.payment.productIdentifier];
			default:
				break;
		}
		// Remove the transaction from the payment queue.
		[[SKPaymentQueue defaultQueue] finishTransaction: transaction];
	}
}*/

@end
