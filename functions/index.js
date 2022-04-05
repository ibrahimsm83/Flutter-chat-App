'use strict';

const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

/**
 * Sends a notification to the recipient when a message is sent to.
 */
exports.sendNewMessageNotification = functions.firestore.document('/messages/{chatId}/{chat_id}/{timestamp}')
    .onCreate(async(snap, context) => {
        const message = snap.data();
        // Get the list of device notification tokens.
        const getRecipientPromise = admin.firestore().collection('users').doc(message.to).get();

        // The snapshot to the user's tokens.
        let recipient;

        // The array containing all the user's tokens.
        let tokens;

        const results = await Promise.all([getRecipientPromise]);

        recipient = results[0];


        tokens = recipient.data().notificationTokens || [];

        // Check if there are any device tokens.
        if (tokens.length === 0) {
            return console.log('There are no notification tokens to send to.');
        }
        // if (recipient.data().lastSeen === true) {
        //     return console.log('User is Online. So no need to send message.');
        // }

        // Notification details.
        const payload = {
            notification: {
                title: 'You have new message(s)',
                body: 'New message(s) recieved.',
                click_action: 'FLUTTER_NOTIFICATION_CLICK',
                priority: "high",
                sound: 'default',
            },
            data: {
                'title': 'You have new message(s)',
                'body': 'New message(s) recieved.',
                'peerid': message.from,
                'click_action': 'FLUTTER_NOTIFICATION_CLICK',
            },

        };

        // Send notifications to all tokens.
        const response = await admin.messaging().sendToDevice(tokens, payload);
        // For each message check if there was an error.
        const tokensToRemove = [];
        response.results.forEach((result, index) => {
            const error = result.error;
            if (error) {
                console.error('Failure sending notification to', tokens[index], error);
                // Cleanup the tokens who are not registered anymore.
                if (error.code === 'messaging/invalid-registration-token' ||
                    error.code === 'messaging/registration-token-not-registered') {
                    tokensToRemove.push(tokens[index]);
                }
            }
        });
        return recipient.ref.update({
            notificationTokens: tokens.filter((token) => !tokensToRemove.includes(token))
        });
    });




exports.newIncomingCall = functions.firestore.document('/users/{userId}/callhistory/{callId}')
    .onCreate(async(snap, context) => {
        const message = snap.data();

        if (message['TYPE'] === 'OUTGOING') {
            return console.log('Skipped Notification as it is Outgoing Call.');
        } else {


            // Get the list of device notification tokens.
            const getRecipientPromise = admin.firestore().collection('users').doc(message['TARGET']).get();

            // The snapshot to the user's tokens.
            let recipient;

            // The array containing all the user's tokens.
            let tokens;

            const results = await Promise.all([getRecipientPromise]);

            recipient = results[0];


            tokens = recipient.data().notificationTokens || [];

            // Check if there are any device tokens.
            if (tokens.length === 0) {
                return console.log('There are no notification tokens to send to.');
            }
            let payload;
            // Notification details.
            if (message['ISVIDEOCALL'] == true) {
                payload = {
                    //  Disabled the notification property so that onbackgroundmessage can be triggered--------
                    // notification: {
                    //     title: 'Incoming Video Call...',
                    //     body: 'Accept / Reject the Call',
                    //     click_action: 'FLUTTER_NOTIFICATION_CLICK',

                    //     priority: 'high',
                    //     sound: 'default'

                    // },


                    data: {
                        'dp': message['DP'],
                        'title': 'Incoming Video Call...',
                        'body': 'Accept / Reject the Call',
                        'click_action': 'FLUTTER_NOTIFICATION_CLICK',
                    }

                }
                var options = {
                    priority: 'high',
                    contentAvailable: true,

                };
            } else {
                payload = {
                    //  Disabled the notification property so that onbackgroundmessage can be triggered--------
                    // notification: {
                    //     title: 'Incoming Audio Call...',
                    //     body: 'Accept / Reject the Call',
                    //     click_action: 'FLUTTER_NOTIFICATION_CLICK',

                    //     priority: 'high',
                    //     sound: 'default'


                    // },



                    data: {
                        'dp': message['DP'],
                        'title': 'Incoming Audio Call...',
                        'body': 'Accept / Reject the Call',
                        'click_action': 'FLUTTER_NOTIFICATION_CLICK',
                    }

                }
                var options = {
                    priority: 'high',
                    contentAvailable: true,

                };

            }


            // Send notifications to all tokens.
            const response = await admin.messaging().sendToDevice(tokens, payload, options);
            // For each message check if there was an error.
            const tokensToRemove = [];
            response.results.forEach((result, index) => {
                const error = result.error;
                if (error) {
                    console.error('Failure sending notification to', tokens[index], error);
                    // Cleanup the tokens who are not registered anymore.
                    if (error.code === 'messaging/invalid-registration-token' ||
                        error.code === 'messaging/registration-token-not-registered') {
                        tokensToRemove.push(tokens[index]);
                    }
                }
            });
            return recipient.ref.update({
                notificationTokens: tokens.filter((token) => !tokensToRemove.includes(token))
            });
        }
    });

exports.callRejectedFirstTime = functions.firestore.document('/users/{userId}/recent/callended')
    .onCreate(async(snap, context) => {
        const message = snap.data();

        // if (message['TYPE'] === 'OUTGOING') {
        //     return console.log('Skipped Notification as it is Outgoing Call.');
        // } else {


        // Get the list of device notification tokens.
        const getRecipientPromise = admin.firestore().collection('users').doc(message['id']).get();

        // The snapshot to the user's tokens.
        let recipient;

        // The array containing all the user's tokens.
        let tokens;

        const results = await Promise.all([getRecipientPromise]);

        recipient = results[0];


        tokens = recipient.data().notificationTokens || [];

        // Check if there are any device tokens.
        if (tokens.length === 0) {
            return console.log('There are no notification tokens to send to.');
        }
        let payload;
        // Notification details.

        payload = {
            notification: {
                title: 'Call Ended',
                body: 'Incoming Call ended',
                click_action: 'FLUTTER_NOTIFICATION_CLICK',
                priority: "high",
                sound: 'default'

            },

            data: {
                "body": 'Incoming Call ended',
                "title": 'Call Ended',
                "click_action": "FLUTTER_NOTIFICATION_CLICK",


            },


        }
        var options = {
            priority: 'high',
            contentAvailable: true,

        };



        // Send notifications to all tokens.
        const response = await admin.messaging().sendToDevice(tokens, payload, options);
        // For each message check if there was an error.
        const tokensToRemove = [];
        response.results.forEach((result, index) => {
            const error = result.error;
            if (error) {
                console.error('Failure sending notification to', tokens[index], error);
                // Cleanup the tokens who are not registered anymore.
                if (error.code === 'messaging/invalid-registration-token' ||
                    error.code === 'messaging/registration-token-not-registered') {
                    tokensToRemove.push(tokens[index]);
                }
            }
        });
        return recipient.ref.update({
            notificationTokens: tokens.filter((token) => !tokensToRemove.includes(token))
        });
        // }
    });





exports.callRejectedNotFirstTime = functions.firestore.document('/users/{userId}/recent/callended')
    .onUpdate(async(change, context) => {
        const message = change.after.data();

        // if (message['TYPE'] === 'OUTGOING') {
        //     return console.log('Skipped Notification as it is Outgoing Call.');
        // } else {


        // Get the list of device notification tokens.
        const getRecipientPromise = admin.firestore().collection('users').doc(message['id']).get();

        // The snapshot to the user's tokens.
        let recipient;

        // The array containing all the user's tokens.
        let tokens;

        const results = await Promise.all([getRecipientPromise]);

        recipient = results[0];

        tokens = recipient.data().notificationTokens || [];

        // Check if there are any device tokens.
        if (tokens.length === 0) {
            return console.log('There are no notification tokens to send to.');
        }
        let payload;
        // Notification details.

        payload = {
            notification: {
                title: 'Call Ended',
                body: 'Incoming Call ended',
                click_action: 'FLUTTER_NOTIFICATION_CLICK',
                priority: "high",
                sound: 'default',
            },
            data: {
                "body": 'Incoming Call ended',
                "title": 'Call Ended',
                "click_action": "FLUTTER_NOTIFICATION_CLICK",


            },






        }

        var options = {
            priority: 'high',
            contentAvailable: true,

        };
        // Send notifications to all tokens.
        const response = await admin.messaging().sendToDevice(tokens, payload, options);
        // For each message check if there was an error.
        const tokensToRemove = [];
        response.results.forEach((result, index) => {
            const error = result.error;
            if (error) {
                console.error('Failure sending notification to', tokens[index], error);
                // Cleanup the tokens who are not registered anymore.
                if (error.code === 'messaging/invalid-registration-token' ||
                    error.code === 'messaging/registration-token-not-registered') {
                    tokensToRemove.push(tokens[index]);
                }
            }
        });
        return recipient.ref.update({
            notificationTokens: tokens.filter((token) => !tokensToRemove.includes(token))
        });
        // }
    });