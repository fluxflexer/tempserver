#!/usr/bin/perl

# If using interupts the HiPi::Interrupt module should be used
# before anything else in your script. This is because the
# module loads threads to handle interrupts for pins managed
# by HiPi::Device::GPIO, HiPi::BCM2835 and HiPi::Wiring.
# Loading first reduces your memory footprint and avoids issues
# with modules you may use that are not thread safe.

use HiPi::Interrupt;

# Some basic modules loaded

use 5.14.0;
use strict;
use warnings;
use HiPi::Device::GPIO;
use HiPi::Constant qw( :raspberry );

#-------------------------------------------------------------

package MyInterruptHandler;

#-------------------------------------------------------------
# To handle interrupts we create a class deriving from
# HiPi::Interrupt::Handler and override the on_action_....
# methods.
#-------------------------------------------------------------
use strict;
use warnings;
use parent qw( HiPi::Interrupt::Handler );
use HiPi::Constant qw( :raspberry );

sub new {
    my($class, %params) = @_;
    $class->SUPER::new(%params);
}


#----------------------------------------------
# Action Events Handling - these events will be
# called in response to actions in the interrupt
# handling threads. For this example we just
# print the info STDOUT
#------------------------------------------

sub on_action_add {
    my($self, $msg) = @_;
    # we get this message after we have added a pin

    # check if( $msg->error ) to see if there was an
    # error. When $msg->error is true, error details
    # are in $msg->msgtext

    $self->do_handle_message( $msg );
}

sub on_action_remove {
    my($self, $msg) = @_;
    # we get this message after we have removed a pin

    # check if( $msg->error ) to see if there was an
    # error. When $msg->error is true, error details
    # are in $msg->msgtext

    $self->do_handle_message( $msg );
}

sub on_action_interrupt {
    my($self, $msg) = @_;

    # we get this message after we have detected an interrupt

    # check if( $msg->error ) to see if there was an
    # error. When $msg->error is true, error details
    # are in $msg->msgtext

    $self->do_handle_message( $msg );
}

sub on_action_error {
    my($self, $msg) = @_;

    # we get this message after a generic error
    # error details are in $msg->msgtext

    $self->do_handle_message( $msg );
}

sub on_action_continue {
    my ($self, $actions) = @_;

    # this gets called at a maximum interval of polltimeout
    # and is always called after an interrupt is detected and
    # handled. If the call is after 1 or more interrupt
    # detections $actions will contain the number of interrupts
    # detected. If this is called after interrupt detection
    # times out then $actions == 0

    $self->{hbcounter} ++;
    unless( $self->{hbcounter} % 100 ) {
        say qq(on_action_continue called $self->{hbcounter} times);
    }

    # exit after 1000 calls
    $self->stop if $self->{hbcounter} == 1000;
}

sub on_action_start {
    my $self = shift;
    say 'INTERRUPT POLLING STARTED';
}

sub on_action_stop {
    my $self = shift;
    say 'INTERRUPT POLLING FINISHED';
}

sub do_handle_message {
    my ($self, $msg ) = @_;
    say'--------------------------------';
    my $output =  ( $msg->error ) ? 'ERROR MESSAGE' : uc($msg->action) . ' HANDLED';
    say $output;
    say qq(  action    : ) . $msg->action;
    say qq(  pinid     : ) . $msg->pinid;
    say qq(  error     : ) . $msg->error;
    say qq(  value     : ) . $msg->value;
    say qq(  timestamp : ) . $msg->timestamp;
    say qq(  msgtext   : ) . $msg->msgtext;
    say qq(  pinclass  : ) . $msg->pinclass;
    say'--------------------------------';
}


# return to default package main
#-------------------------------------------------------------

package main;

#-------------------------------------------------------------

# create our interrupt handler
my $handler = MyInterruptHandler->new;

{
    # the pins we are going to use
    my $pinid1 = RPI_PAD1_PIN_13;
    my $pinid2 = RPI_PAD1_PIN_11;

    my $dev = HiPi::Device::GPIO->new;

    # setup a pin as input with a pull up
    # resistor and falling edge interrupt
    # using HiPi::Device::GPIO

    $dev->export_pin($pinid1);
    my $pin1 = $dev->get_pin($pinid1);
    $pin1->mode(RPI_PINMODE_INPT);
    $pin1->set_pud(RPI_PUD_OFF);
    $pin1->set_pud(RPI_PUD_UP);
    $pin1->interrupt( RPI_INT_FALL );

    # setup a pin as input with a pull down
    # resistor and rising edge interrupt
    # using HiPi::Device::GPIO

    # use the pin obj returned from
    # the export_pin method

    my $pin2 = $dev->export_pin($pinid2);

    $pin2->mode(RPI_PINMODE_INPT);
    $pin2->set_pud(RPI_PUD_OFF);
    $pin2->set_pud(RPI_PUD_DOWN);
    $pin2->interrupt( RPI_INT_RISE );

    # add as many pins as we want
    $handler->add_pin($pin1);
    $handler->add_pin($pin2);
}

# run the application loop
$handler->poll();

1;